// AudioFX: glow in the wallpaper.
//
// Draws ONLY light: output with alpha 0 and color > 0 is purely additive on
// the wallpaper below, because Qt and Wayland use premultiplied alpha.
// Wherever nothing glows, the output is 0.
//
// Textures from audiofx-glow.py:
//   coreTex  R        core (full resolution)
//   infoTex  R bloom, G position in the spectrum, B phase
//   distTex  R distance inside the spot (for "flow")

#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    float fillMode;     // 0 stretch, 1 fit, 2 crop (anything else like crop)
    float imgW;
    float imgH;
    float scrW;
    float scrH;

    float mode;         // 0 sync, 1 by pitch, 2 flow, 3 sparkle, 4 spectrum across the width
    float time;         // seconds
    float level;        // overall level 0..1 (bass-weighted, with beat kick)
    float idle;         // base glow 0..1 (paused / breathing)
    float strength;     // core gain
    float bloom;        // bloom gain
    float speed;        // flow: half diagonals per second
    vec4 color;
    float spotColors;   // 1: every spot glows in its own color from the image

    vec4 b0;            // 16 bands, low -> high
    vec4 b1;
    vec4 b2;
    vec4 b3;
    vec4 beatTime;      // last four beats (time)
    vec4 beatStrength;
} ubuf;

layout(binding = 1) uniform sampler2D coreTex;
layout(binding = 2) uniform sampler2D infoTex;
layout(binding = 3) uniform sampler2D distTex;
layout(binding = 4) uniform sampler2D colorTex;

vec2 imageUV(vec2 uv) {
    vec2 scr = vec2(ubuf.scrW, ubuf.scrH);
    vec2 img = vec2(ubuf.imgW, ubuf.imgH);
    if (ubuf.fillMode < 0.5)
        return uv;
    if (ubuf.fillMode < 1.5) {
        float s = min(scr.x / img.x, scr.y / img.y);
        vec2 off = (scr - img * s) * 0.5;
        return ((uv * scr) - off) / (img * s);
    }
    float s = max(scr.x / img.x, scr.y / img.y);
    vec2 off = (img * s - scr) / (img * s);
    return uv * (vec2(1.0) - off) + off * 0.5;
}

float band(float p) {
    float x = clamp(p, 0.0, 1.0) * 15.0;
    int i = int(floor(x));
    int j = min(i + 1, 15);
    float f = fract(x);
    float a[16] = float[16](ubuf.b0.x, ubuf.b0.y, ubuf.b0.z, ubuf.b0.w,
                            ubuf.b1.x, ubuf.b1.y, ubuf.b1.z, ubuf.b1.w,
                            ubuf.b2.x, ubuf.b2.y, ubuf.b2.z, ubuf.b2.w,
                            ubuf.b3.x, ubuf.b3.y, ubuf.b3.z, ubuf.b3.w);
    return mix(a[i], a[j], f);
}

float hash(float n) {
    return fract(sin(n * 12.9898) * 43758.5453);
}

void main() {
    vec2 uv = imageUV(qt_TexCoord0);
    if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
        fragColor = vec4(0.0);
        return;
    }

    vec4 info = texture(infoTex, uv);
    float halo = info.r;
    if (halo < 0.004) {
        fragColor = vec4(0.0);
        return;
    }
    float core = texture(coreTex, uv).r;
    float pos = info.g;
    float phase = info.b;
    float dist = ubuf.mode > 1.5 && ubuf.mode < 2.5 ? texture(distTex, uv).r : 0.0;

    float drive = 0.0;
    if (ubuf.mode < 0.5) {
        drive = ubuf.level;
    } else if (ubuf.mode < 1.5) {
        drive = band(pos) * 1.25;
    } else if (ubuf.mode < 2.5) {
        // light fronts travel along the distance, starting at the spot's edge
        float width = 0.035;
        for (int k = 0; k < 4; k++) {
            float t = ubuf.time - ubuf.beatTime[k];
            if (t < 0.0 || t > 6.0)
                continue;
            float front = t * ubuf.speed;
            float d = (dist - front) / width;
            // slow afterglow behind the front, nothing ahead of it
            float trail = d < 0.0 ? exp(d * 0.35) : exp(-d * d);
            drive += ubuf.beatStrength[k] * trail * exp(-t * 0.9);
        }
        drive = drive + ubuf.level * 0.25;
    } else if (ubuf.mode < 3.5) {
        // every spot flickers at its own rate, driven by mids and highs
        float rate = 5.0 + phase * 9.0;
        float z = ubuf.time * rate + phase * 97.0;
        float a = hash(floor(z) + phase * 311.0);
        float b = hash(floor(z) + 1.0 + phase * 311.0);
        float flicker = mix(a, b, smoothstep(0.0, 1.0, fract(z)));
        float push = band(0.35 + pos * 0.6) * 1.3 + ubuf.level * 0.35;
        drive = push * (0.25 + 0.95 * flicker * flicker);
    } else {
        drive = band(qt_TexCoord0.x) * 1.3;
    }

    drive = max(drive, 0.0) + ubuf.idle;
    float light = core * ubuf.strength * drive + halo * ubuf.bloom * drive * 0.55;
    // above 1 keep getting brighter instead of clipping
    light = light / (1.0 + 0.35 * light);
    vec3 tone = ubuf.spotColors > 0.5 ? texture(colorTex, uv).rgb : ubuf.color.rgb;
    vec3 rgb = tone * light;
    // white core on strong peaks
    rgb += vec3(1.0, 0.92, 0.8) * max(0.0, core * drive * ubuf.strength - 0.9) * 0.35;
    fragColor = vec4(rgb, 0.0) * ubuf.qt_Opacity;
}
