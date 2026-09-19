# AudioFX

**English** · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · [简体中文](README.zh_CN.md)

A plugin for [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) with three audio visuals: a visualizer along a screen edge, a glow that makes the bright spots of your wallpaper pulse to the music, and a round player disc for the desktop.

![AudioFX](assets/screenshot.png)

Step by step with pictures: [installation and setup guide](docs/GUIDE.md).

## Visualizer

The visualizer sits along one screen edge and leaves the DMS frame and bar out. There are eight styles: filled wave, wave as a line, mirrored wave, bars, mirrored bars, hanging bars, blocks and dots. Color, opacity, depth, number of bands, gaps and frame rate are adjustable.

By default cava only runs while an MPRIS player is playing and ends when playback stops. With "Only during playback" switched off, cava keeps running and also shows sound from programs without MPRIS. A tile in the control center switches the visualizer on and off.

## Glow

The plugin looks for glowing spots in the current wallpaper: bright pixels that stand out from their surroundings. Lamps, embers, neon or lava work well. Large evenly lit areas such as a sky are left out. Under "Which spots glow" you can limit this to the most common color, allow every saturated color, or include bright light without color, such as a sun or a light shaft. Each spot glows in its own color from the image. The analysis runs once per wallpaper and is cached.

The spots then light up with the music. There are five modes:

- All at once: every spot follows bass and volume.
- By pitch: large spots follow the bass, medium ones the mids, small ones the highs.
- Flowing: each bass beat sends a light front along the spots, starting at the image edge.
- Sparkle: each spot flickers at its own rhythm.
- Spectrum across the width: low notes on the left, high notes on the right.

Without playback the glow can stay off, glow quietly or breathe slowly. The color comes from the image or from the DMS accent.

## Player disc

A desktop widget with the round cover of the current track. It spins while playing, shows the track progress as a ring and shows previous, play and next on hover. Around the cover there is a visualizer: a wave like the one in the DMS dashboard, bars in a circle, or a glow ring.

If Pear Desktop (YouTube Music) runs with its API server enabled, the disc loads the cover in 1200 px. MPRIS only delivers 120 px for Chromium based players.

The cover can be tinted in the DMS accent color ("Tint in the accent color"), so it changes with the theme or profile like the rest of the shell.

## Requirements

- DankMaterialShell 1.6.1 or newer
- cava
- For the glow: python3 with numpy and Pillow

I use it on niri. The visualizer and the glow use their own layer surfaces on the background layer. On niri, background surfaces move along with the workspaces unless they are placed in the backdrop. Add these rules to your niri config so both stay in place:

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

The player disc is a regular DMS desktop widget and behaves like the other widgets on your compositor.

## Installation

From the plugin registry:

```sh
dms plugins install audioFx
dms ipc call plugins enable audioFx
```

It is also listed in DMS under Settings → Plugins → Browse. To install from the repository instead:

```sh
git clone https://github.com/satoshoe-dev/dms-audiofx ~/.config/DankMaterialShell/plugins/AudioFx
dms ipc call plugins enable audioFx
```

Add the player disc under Settings → Desktop Widgets → Add Desktop Widget → AudioFX.

## IPC

```sh
dms ipc call audiofx glow on|off|toggle
dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
dms ipc call audiofx set <key> <value>
dms ipc call audiofx get <key>
```

`set` and `get` use the keys from the plugin settings, for example `glowStrength` or `discForm`.

## Performance

The glow covers the whole screen, so the compositor redraws it on every frame while music plays. The frame rate for the glow is set to 30 by default and can be lowered. Outside the glowing spots the shader returns right away.

## Translations

The settings page is available in German, Spanish, French, Italian, Portuguese, Russian, Japanese and Simplified Chinese and follows the language set in DMS. If a translation reads wrong, a pull request is welcome.

## Note

I wrote this plugin with help from Claude (Anthropic) and tested every change on my own niri desktop. `AudioFxHalo.qml` is based on `MediaBlobHalo.qml` from DankMaterialShell (MIT, Copyright (c) 2025 Avenge Media LLC).

## License

MIT
