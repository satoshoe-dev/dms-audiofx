#!/usr/bin/env python3
"""AudioFX: glow mask from a wallpaper.

Finds the glowing spots of an image (saturated AND bright, in one shared hue)
and writes the textures the glow shader reads:

  core.png   L, full resolution: how strongly a pixel itself may glow
  info.png   RGB, quarter resolution:
               R  bloom (blurred core, the halo)
               G  position in the spectrum (0 low ... 1 high), per spot
               B  random phase per spot (for "sparkle")
  dist.png   L, quarter resolution: distance inside the spot from its pixel
             closest to the image border (for "flow"), in pixels / half
             diagonal

A "spot" is a connected glowing area after a slight dilation, so that the
broken cracks of a hand stay one spot.

Spectrum assignment: the large spots (together half of the glowing area)
belong to the bass, the next 30 % to the mids, the many small ones to the
highs. Slightly scattered within each group so the lamps don't all twitch in
exact unison.

Output on stdout: one line of JSON with paths, color and statistics. If the
result for the same image (path, size, mtime) and the same parameters is
already cached, nothing is recomputed.

Dependencies: numpy, Pillow. No scipy.
"""

import argparse
import colorsys
import hashlib
import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

VERSION = 11  # bump on any change to the computation or output -> invalidates the cache


def log(*a):
    print(*a, file=sys.stderr)


def shifts_max(m, r):
    """Dilate by r pixels (square) via shifted maxima."""
    out = m.copy()
    for _ in range(r):
        n = out.copy()
        n[1:, :] |= out[:-1, :]
        n[:-1, :] |= out[1:, :]
        n[:, 1:] |= out[:, :-1]
        n[:, :-1] |= out[:, 1:]
        out = n
    return out


def label(mask):
    """Connected areas (4-neighborhood) without scipy.

    Every pixel starts with its own flat index; then the minimum of the
    neighbors is taken repeatedly and shortened by pointer jumping
    (lab = lab[lab]). Converges in a few dozen rounds.
    """
    h, w = mask.shape
    big = h * w
    lab = np.where(mask, np.arange(big).reshape(h, w), big)
    for _ in range(4000):
        prev = lab
        n = lab.copy()
        n[1:, :] = np.minimum(n[1:, :], lab[:-1, :])
        n[:-1, :] = np.minimum(n[:-1, :], lab[1:, :])
        n[:, 1:] = np.minimum(n[:, 1:], lab[:, :-1])
        n[:, :-1] = np.minimum(n[:, :-1], lab[:, 1:])
        n = np.where(mask, n, big)
        flat = np.append(n.ravel(), big)
        for _ in range(3):
            flat[:-1] = np.where(flat[:-1] < big, flat[flat[:-1]], big)
        lab = flat[:-1].reshape(h, w)
        if np.array_equal(lab, prev):
            break
    ids, inv = np.unique(lab, return_inverse=True)
    inv = inv.reshape(h, w)
    # "big" (no label) becomes -1
    if ids[-1] == big:
        inv = np.where(lab == big, -1, inv)
        ids = ids[:-1]
    return inv, len(ids)


def nearest_fill(lab, r):
    """Spread labels into their neighborhood over r rounds (for the bloom)."""
    out = lab.copy()
    for _ in range(r):
        empty = out < 0
        if not empty.any():
            break
        n = out.copy()
        for a, b in (
            ((slice(1, None), slice(None)), (slice(None, -1), slice(None))),
            ((slice(None, -1), slice(None)), (slice(1, None), slice(None))),
            ((slice(None), slice(1, None)), (slice(None), slice(None, -1))),
            ((slice(None), slice(None, -1)), (slice(None), slice(1, None))),
        ):
            dst = n[a]
            src = out[b]
            take = (dst < 0) & (src >= 0)
            dst[take] = src[take]
        out = n
    return out


def geodesic(mask, lab, n_labels):
    """Distance inside each spot, starting from the spot's pixel closest to the border."""
    h, w = mask.shape
    yy, xx = np.mgrid[0:h, 0:w]
    border = np.minimum.reduce([xx, yy, w - 1 - xx, h - 1 - yy]).astype(np.int32)
    dist = np.full((h, w), -1, np.int32)
    flat_lab = lab.ravel()
    flat_border = border.ravel()
    valid = flat_lab >= 0
    idx = np.nonzero(valid)[0]
    # per label, the pixel with the smallest border distance
    order = np.lexsort((flat_border[idx], flat_lab[idx]))
    ordered = idx[order]
    first = np.unique(flat_lab[ordered], return_index=True)[1]
    start = ordered[first]
    dist.ravel()[start] = 0
    front = np.zeros((h, w), bool)
    front.ravel()[start] = True
    step = 0
    while front.any():
        step += 1
        n = np.zeros_like(front)
        n[1:, :] |= front[:-1, :]
        n[:-1, :] |= front[1:, :]
        n[:, 1:] |= front[:, :-1]
        n[:, :-1] |= front[:, 1:]
        n &= mask & (dist < 0)
        dist[n] = step
        front = n
        if step > h + w:
            break
    return dist


def blur(a, sigma):
    """Floating-point Gaussian, separated into rows and columns (no scipy)."""
    r = max(1, int(sigma * 3))
    x = np.arange(-r, r + 1, dtype=np.float32)
    k = np.exp(-(x * x) / (2 * sigma * sigma))
    k /= k.sum()
    p = np.pad(a.astype(np.float32), r, mode="constant")
    rows = np.apply_along_axis(lambda v: np.convolve(v, k, mode="same"), 1, p)
    cols = np.apply_along_axis(lambda v: np.convolve(v, k, mode="same"), 0, rows)
    return cols[r:-r, r:-r]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--cache", default=os.path.expanduser("~/.cache/DankMaterialShell/audiofx-glow"))
    ap.add_argument("--threshold", type=int, default=50, help="0 finds a lot, 100 only the strongest")
    # hue: the most common saturated hue, all: every saturated color,
    # light: saturated colors plus bright light sources without color
    ap.add_argument("--colors", choices=["hue", "all", "light"], default="hue")
    ap.add_argument("--force", action="store_true", help="recompute even if cached")
    a = ap.parse_args()

    path = Path(a.image)
    st = path.stat()
    key = hashlib.sha1(
        f"{VERSION}|{path.resolve()}|{st.st_size}|{st.st_mtime_ns}|{a.threshold}|{a.colors}".encode()
    ).hexdigest()[:16]
    out_dir = Path(a.cache) / key
    meta = out_dir / "meta.json"
    if meta.exists() and not a.force:
        print(meta.read_text().strip())
        return

    im = Image.open(path).convert("RGB")
    W, H = im.size
    # compute very large images at no more than 3840 px width
    if W > 3840:
        im = im.resize((3840, round(H * 3840 / W)), Image.LANCZOS)
        W, H = im.size

    hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255.0
    hue = hsv[..., 0] * 360.0
    sat = hsv[..., 1]
    val = hsv[..., 2]

    # Local contrast: brightness against the surroundings (blurred at 1/8,
    # ~2.5 % of the width). Glowing spots stand out, large evenly bright areas
    # (an evening sky) don't. Without it, a quarter of a sunset image glowed as
    # one flat area.
    small = Image.fromarray((val * 255).astype(np.uint8)).resize((max(8, W // 8), max(8, H // 8)), Image.BOX)
    small = small.filter(ImageFilter.GaussianBlur(max(2.0, W / 8 * 0.025)))
    surround = np.asarray(small.resize((W, H), Image.BILINEAR)).astype(np.float32) / 255.0
    contrast = val - surround

    # Threshold 0..100 -> saturation 0.25..0.70, brightness 0.20..0.60, contrast 0.04..0.14.
    # If it finds more than 6 % of the image, it is raised step by step.
    t = max(0, min(100, a.threshold)) / 100.0
    glow_hue = None
    for _ in range(8):
        s0 = 0.25 + 0.45 * t
        v0 = 0.20 + 0.40 * t
        k0 = 0.04 + 0.10 * t
        candidate = (sat > s0) & (val > v0) & ((contrast > k0) | ((val > 0.93) & (sat > 0.5) & (contrast > k0 * 0.3)))
        if a.colors == "hue" and candidate.sum() > 50:
            # most common hue among the candidates, weighted by saturation*brightness
            weights = (sat * val)[candidate]
            hist, _ = np.histogram(hue[candidate], bins=36, range=(0, 360), weights=weights)
            hist = hist + 0.5 * (np.roll(hist, 1) + np.roll(hist, -1))
            glow_hue = (np.argmax(hist) + 0.5) * 10.0
            hue_dist = np.abs((hue - glow_hue + 180.0) % 360.0 - 180.0)
            candidate &= hue_dist < 28.0
        if candidate.mean() <= 0.06 or t >= 1.0:
            break
        t = min(1.0, t + 0.12)

    # Core without hard thresholds: every condition as a soft ramp instead of
    # yes/no, otherwise the mask boundaries draw visible flat patches.
    # `candidate` only serves the statistics (hue, share).
    def ramp(x, a, b):
        return np.clip((x - a) / max(1e-6, b - a), 0, 1)
    w_sat = ramp(sat, s0 - 0.08, s0 + 0.22)
    w_val = ramp(val, v0 - 0.08, v0 + 0.28)
    w_con = ramp(contrast, k0 * 0.4, k0 * 1.6)
    w_con = np.maximum(w_con, ramp(val, 0.9, 0.97) * ramp(sat, 0.45, 0.6) * ramp(contrast, k0 * 0.15, k0 * 0.5))
    if glow_hue is not None:
        hue_dist = np.abs((hue - glow_hue + 180.0) % 360.0 - 180.0)
        w_hue = 1.0 - ramp(hue_dist, 18.0, 36.0)
    else:
        w_hue = 1.0
    core = (w_sat * w_val * w_con * w_hue).astype(np.float32)
    core = core * core * (3.0 - 2.0 * core)
    # Density: share of glow pixels in a wide radius. Flat areas have high
    # density, lines, lamps and cracks low density; flat areas don't glow.
    km = Image.fromarray((candidate * 255).astype(np.uint8)).resize((max(8, W // 8), max(8, H // 8)), Image.BOX)
    km = km.filter(ImageFilter.GaussianBlur(max(2.0, W / 8 * 0.03)))
    density = np.asarray(km.resize((W, H), Image.BILINEAR)).astype(np.float32) / 255.0
    core = (core * np.clip((0.5 - density) / 0.3, 0, 1)).astype(np.float32)

    if a.colors == "light":
        # Bright light sources without color (sun, lamps, a light shaft). They
        # stand out from the surroundings but may be larger than colored spots,
        # so the density limit is more lenient.
        lv0 = 0.80 + 0.12 * t
        lk0 = 0.06 + 0.08 * t
        light_candidate = (val > lv0) & (contrast > lk0)
        w_light = ramp(val, lv0 - 0.06, lv0 + 0.08) * ramp(contrast, lk0 * 0.5, lk0 * 1.5)
        lm = Image.fromarray((light_candidate * 255).astype(np.uint8)).resize((max(8, W // 8), max(8, H // 8)), Image.BOX)
        lm = lm.filter(ImageFilter.GaussianBlur(max(2.0, W / 8 * 0.03)))
        light_density = np.asarray(lm.resize((W, H), Image.BILINEAR)).astype(np.float32) / 255.0
        light_core = w_light * np.clip((0.85 - light_density) / 0.3, 0, 1)
        light_core = light_core * light_core * (3.0 - 2.0 * light_core)
        core = np.maximum(core, light_core).astype(np.float32)
        candidate = candidate | light_candidate

    share = float((core > 0.15).mean())

    # Glow color: mean color of the strongest core pixels, at full brightness
    rgb = np.asarray(im).astype(np.float32) / 255.0
    strong = core > 0.6
    if strong.sum() > 20:
        mean = rgb[strong].mean(axis=0)
    elif glow_hue is not None:
        mean = np.array(colorsys.hsv_to_rgb(glow_hue / 360.0, 0.85, 1.0))
    else:
        mean = np.array([1.0, 0.55, 0.15])
    hh, ss, vv = colorsys.rgb_to_hsv(*mean)
    glow_rgb = colorsys.hsv_to_rgb(hh, min(1.0, ss * 1.05), 1.0)

    # ---------------------------------------------------------- quarter grid
    w4, h4 = max(8, W // 4), max(8, H // 4)
    # maximum per 4x4 block instead of the mean: otherwise fine cracks vanish
    core4 = core[: h4 * 4, : w4 * 4].reshape(h4, 4, w4, 4).max(axis=(1, 3))
    mask4 = core4 > 0.04
    joined = shifts_max(mask4, 3)
    lab, n = label(joined)
    lab = np.where(mask4 | joined, lab, -1)

    sizes = np.bincount(lab[lab >= 0], weights=core4[lab >= 0], minlength=n) if n else np.zeros(0)
    rng = np.random.default_rng(int(key[:8], 16))
    spectrum = np.zeros(n, np.float32)
    phase = rng.random(n).astype(np.float32)
    if n:
        order = np.argsort(-sizes)
        cumulative = np.cumsum(sizes[order]) / max(1e-6, sizes.sum())
        for rank, i in enumerate(order):
            share_before = cumulative[rank] - sizes[i] / max(1e-6, sizes.sum())
            if share_before < 0.5:
                lo, hi = 0.0, 0.18
            elif share_before < 0.8:
                lo, hi = 0.25, 0.55
            else:
                lo, hi = 0.55, 1.0
            spectrum[i] = lo + (hi - lo) * rng.random()

    dist = geodesic(joined, lab, n)
    half_diag = 0.5 * float(np.hypot(w4, h4))
    dist_n = np.where(dist >= 0, np.clip(dist / half_diag, 0, 1), 0).astype(np.float32)

    # Bloom: blur the core, radius ~1.2 % of the width
    radius = max(2.0, w4 * 0.012)
    # Blur in floating point: from 8-bit steps the square root below makes
    # visible stairs (a jump from 0 to 0.06 at the edge of the halo)
    bloom = blur(core4, radius)
    wide = blur(core4, radius * 3.5)
    bloom = 0.8 * bloom + 0.2 * wide
    if bloom.max() > 0:
        top = np.percentile(bloom[bloom > 0.01], 99.5) if (bloom > 0.01).any() else bloom.max()
        bloom = np.clip(bloom / max(top, 1e-4), 0, 1)
        # A power below 1 lifts the bloom of small spots (lamps, an eye) so one
        # large lava area does not dominate. A square root spread the halo over
        # a third of some images, 0.6 keeps it near the spots.
        bloom = np.power(bloom, 0.6) * np.clip(bloom / 0.02, 0, 1)

    # Spread spot values into the bloom: every pixel in reach takes spectrum,
    # phase and distance of the nearest spot pixel
    reach = int(radius * 4) + 2
    source = np.where(lab >= 0, np.arange(w4 * h4).reshape(h4, w4), -1)
    source = nearest_fill(source, reach)
    has = source >= 0
    q = np.clip(source, 0, None).ravel()
    lab_full = np.where(has, lab.ravel()[q].reshape(h4, w4), -1)
    dist_full = np.where(has, dist_n.ravel()[q].reshape(h4, w4), 0.0)

    if n:
        g = np.where(lab_full >= 0, spectrum[np.clip(lab_full, 0, n - 1)], 0.5)
        b = np.where(lab_full >= 0, phase[np.clip(lab_full, 0, n - 1)], 0.0)
    else:
        g = np.full((h4, w4), 0.5, np.float32)
        b = np.zeros((h4, w4), np.float32)

    # No alpha channel in the textures: Qt premultiplies RGB with alpha on
    # load, so wherever the distance is 0 the bloom would vanish too (hard
    # edges).
    # Soft transitions between spots: spectrum position, phase and distance
    # otherwise jump at the border of two spots and draw jagged contours into
    # the bloom. Weighted blur: only pixels with bloom count, so the empty
    # surroundings don't pull the values toward the middle.
    weight = np.maximum(bloom, (lab_full >= 0) * 0.02).astype(np.float32)
    sigma = max(4.0, radius * 3.0)
    norm = blur(weight, sigma)
    def smooth(values, empty):
        z = blur(values * weight, sigma)
        return np.where(norm > 1e-4, z / np.maximum(norm, 1e-4), empty).astype(np.float32)
    g = smooth(g, 0.5)
    b = smooth(b, 0.0)
    dist_full = smooth(dist_full, 0.0)

    # Color per spot: every spot glows in its own color (orange lamps orange,
    # a white light shaft warm white). Mean color of the core in each 4x4
    # block at full brightness, carried into the bloom like the other values.
    rgb_full = np.asarray(im).astype(np.float32) / 255.0
    rgb_norm = rgb_full / np.maximum(rgb_full.max(axis=-1, keepdims=True), 0.05)
    cw = core[: h4 * 4, : w4 * 4].reshape(h4, 4, w4, 4)
    cr = rgb_norm[: h4 * 4, : w4 * 4].reshape(h4, 4, w4, 4, 3)
    csum = cw.sum(axis=(1, 3))
    block_color = (cr * cw[..., None]).sum(axis=(1, 3)) / np.maximum(csum, 1e-4)[..., None]
    fallback = np.array(glow_rgb, np.float32)
    block_color = np.where((csum > 1e-3)[..., None], block_color, fallback)
    spread = block_color.reshape(-1, 3)[q].reshape(h4, w4, 3)
    spot_color = np.where(has[..., None], spread, fallback)
    spot_color = np.stack([smooth(spot_color[..., c], float(fallback[c])) for c in range(3)], axis=-1)

    info = np.stack([bloom, g, b], axis=-1)
    out_dir.mkdir(parents=True, exist_ok=True)
    # soften the contours of the spots themselves, no hard pixel edge
    core_img = Image.fromarray((core * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(max(1.5, W / 900.0)))
    core_img.save(out_dir / "core.png", optimize=False, compress_level=1)
    Image.fromarray((np.clip(info, 0, 1) * 255).astype(np.uint8), "RGB").save(out_dir / "info.png", compress_level=1)
    Image.fromarray((np.clip(dist_full, 0, 1) * 255).astype(np.uint8), "L").save(out_dir / "dist.png", compress_level=1)
    Image.fromarray((np.clip(spot_color, 0, 1) * 255).astype(np.uint8), "RGB").save(out_dir / "colors.png", compress_level=1)

    result = {
        "core": str(out_dir / "core.png"),
        "info": str(out_dir / "info.png"),
        "dist": str(out_dir / "dist.png"),
        "colors": str(out_dir / "colors.png"),
        "width": W,
        "height": H,
        "color": "#%02x%02x%02x" % tuple(int(round(c * 255)) for c in glow_rgb),
        "share": round(share, 4),
        "spots": int(n),
    }
    meta.write_text(json.dumps(result))
    print(json.dumps(result))


if __name__ == "__main__":
    main()
