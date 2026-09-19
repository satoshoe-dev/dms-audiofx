# AudioFX: step by step

**English** · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · [简体中文](GUIDE.zh_CN.md)

## 1. Install what it needs

AudioFX reads the audio through cava. The glow additionally needs python3 with numpy and Pillow.

```sh
# Arch
sudo pacman -S cava python-numpy python-pillow
# Fedora
sudo dnf install cava python3-numpy python3-pillow
```

## 2. Install and enable the plugin

From the plugin registry:

```sh
dms plugins install audioFx
```

Or clone the repository into your DMS plugin folder:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
```

Open Settings → Plugins and switch AudioFX on.

![Plugin list with AudioFX](images/01-plugin-list.png)

## 3. niri only: keep it in place

On niri, background surfaces move with the workspaces unless they sit in the backdrop. Add these rules to `~/.config/niri/config.kdl`:

```kdl
layer-rule {
    match namespace="^audiofx$"
    place-within-backdrop true
}
layer-rule {
    match namespace="^audiofx-glow$"
    place-within-backdrop true
}
```

Other compositors do not need this.

## 4. The visualizer

Play some music. The visualizer appears along the bottom edge.

![Visualizer at the bottom edge](images/02-visualizer.png)

Expand AudioFX in the plugin list to change it. "Style" switches between waves, bars, blocks and dots. "Edge", "Depth" and "Side inset" place it. "Color" and "Opacity" set the look.

![Visualizer settings](images/03-visualizer-settings.png)

If the bars flicker in quiet passages, raise "Calmness". If they barely move, raise "Sensitivity".

## 5. On and off from the control center

Open the control center, switch to edit mode, click "Add Widget" and choose AudioFX. One click on the tile switches the visualizer on or off.

![AudioFX tile in the control center](images/04-tile.png)

## 6. The glow

Scroll to "Glow in the wallpaper" and switch "Enable glow" on. AudioFX looks for glowing spots in your wallpaper. This takes about a second the first time and is cached afterwards.

![Glow settings](images/05-glow-settings.png)

The glow works best with wallpapers that have small bright light sources: lamps, neon, embers, city lights. On a wallpaper without such spots nothing lights up.

Choose how the spots react under "How the spots pulse":

- All at once
- By pitch
- Flowing
- Sparkle
- Spectrum across the width

![Glowing spots in the wallpaper](images/06-glow.png)

If too much or too little lights up, move "Detection threshold". "Which spots glow" decides whether only the most common color glows, every saturated color, or bright light without color as well. "Glow strength" and "Halo" change the brightness.

## 7. The player disc

Open Settings → Desktop Widgets → Add Desktop Widget and choose AudioFX. Drag the disc to where you want it and resize it.

![Player disc on the desktop](images/07-disc.png)

Hover the disc for previous, play and next. Under "Player disc" in the AudioFX settings choose the visualizer around the cover: a wave, bars in a circle or a glow ring.

## 8. Commands (optional)

```sh
dms ipc call audiofx glow toggle
dms ipc call audiofx mode flow
dms ipc call audiofx set glowStrength 150
```
