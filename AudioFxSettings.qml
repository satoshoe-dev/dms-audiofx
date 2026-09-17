// Visualizer settings. Everything goes into the plugin settings, which DMS
// stores in ~/.config/DankMaterialShell/plugin_settings.json, NOT in
// settings.json. The on/off switch of the control center tile uses the same
// store.
//
// Defaults here must match those in AudioFxCanvas.qml, AudioFxDaemon.qml,
// AudioFxGlow.qml and AudioFxDiscDesktop.qml: until a value is saved, the code
// uses its own fallback, not the one from this page.

import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "audioFx"

    SelectionSetting {
        id: formSetting
        settingKey: "form"
        label: I18n.trFor("audioFx", "Style")
        defaultValue: "waveFilled"
        options: [
            {
                label: I18n.trFor("audioFx", "Filled wave"),
                value: "waveFilled"
            },
            {
                label: I18n.trFor("audioFx", "Wave as a line"),
                value: "wave"
            },
            {
                label: I18n.trFor("audioFx", "Mirrored wave"),
                value: "waveMirrored"
            },
            {
                label: I18n.trFor("audioFx", "Bars"),
                value: "bars"
            },
            {
                label: I18n.trFor("audioFx", "Mirrored bars"),
                value: "barsMirrored"
            },
            {
                label: I18n.trFor("audioFx", "Hanging bars"),
                value: "barsInverted"
            },
            {
                label: I18n.trFor("audioFx", "Blocks"),
                value: "blocks"
            },
            {
                label: I18n.trFor("audioFx", "Dots"),
                value: "dots"
            }
        ]
    }

    readonly property bool isWave: ["wave", "waveFilled", "waveMirrored"].indexOf(formSetting.value) >= 0

    SelectionSetting {
        settingKey: "edge"
        label: I18n.trFor("audioFx", "Edge")
        description: I18n.trFor("audioFx", "Which screen edge the visualizer sits on. The frame and the bar are left out automatically.")
        defaultValue: "bottom"
        options: [
            {
                label: I18n.trFor("audioFx", "Bottom"),
                value: "bottom"
            },
            {
                label: I18n.trFor("audioFx", "Top"),
                value: "top"
            },
            {
                label: I18n.trFor("audioFx", "Left"),
                value: "left"
            },
            {
                label: I18n.trFor("audioFx", "Right"),
                value: "right"
            }
        ]
    }

    SliderSetting {
        settingKey: "depth"
        label: I18n.trFor("audioFx", "Depth")
        description: I18n.trFor("audioFx", "How far the visualizer reaches from the edge into the screen.")
        defaultValue: 160
        minimum: 20
        maximum: 600
        unit: "px"
    }

    SliderSetting {
        settingKey: "sideInset"
        label: I18n.trFor("audioFx", "Side inset")
        description: I18n.trFor("audioFx", "Extra space at both ends, beyond the frame and the bar. The area gets narrower, so the curve tapers off earlier.")
        defaultValue: 0
        minimum: 0
        maximum: 800
        unit: "px"
    }

    ToggleSetting {
        visible: root.isWave
        settingKey: "taper"
        label: I18n.trFor("audioFx", "Taper off at the ends")
        description: I18n.trFor("audioFx", "The curve starts and ends on the baseline instead of breaking off at the edge.")
        defaultValue: true
    }

    SliderSetting {
        visible: root.isWave
        settingKey: "taperWidth"
        label: I18n.trFor("audioFx", "Taper length")
        description: I18n.trFor("audioFx", "Share of the length on each side over which the amplitudes are faded down. Small means a short, steep drop.")
        defaultValue: 15
        minimum: 1
        maximum: 45
        unit: "%"
    }

    SliderSetting {
        settingKey: "bands"
        label: I18n.trFor("audioFx", "Bands")
        description: I18n.trFor("audioFx", "How finely the spectrum is split. More bands cost little, most of the work is the drawing area.")
        defaultValue: 48
        minimum: 4
        maximum: 128
    }

    SliderSetting {
        visible: !root.isWave
        settingKey: "gap"
        label: I18n.trFor("audioFx", "Gap")
        defaultValue: 4
        minimum: 0
        maximum: 32
        unit: "px"
    }

    SliderSetting {
        visible: formSetting.value === "blocks"
        settingKey: "segments"
        label: I18n.trFor("audioFx", "Blocks per bar")
        description: I18n.trFor("audioFx", "The most expensive style: bands × blocks gives the number of elements. With 48 bands and 12 blocks that is 576.")
        defaultValue: 12
        minimum: 4
        maximum: 30
    }

    SliderSetting {
        visible: formSetting.value === "wave"
        settingKey: "lineWidth"
        label: I18n.trFor("audioFx", "Line width")
        defaultValue: 3
        minimum: 1
        maximum: 12
        unit: "px"
    }

    SliderSetting {
        visible: root.isWave
        settingKey: "smoothing"
        label: I18n.trFor("audioFx", "Smoothing")
        description: I18n.trFor("audioFx", "Intermediate points per segment. Higher means rounder between the bands. The shape stays the same, it is just drawn more finely.")
        defaultValue: 8
        minimum: 1
        maximum: 12
    }

    SelectionSetting {
        settingKey: "colorChoice"
        label: I18n.trFor("audioFx", "Color")
        defaultValue: "primary"
        options: [
            {
                label: I18n.trFor("audioFx", "Accent"),
                value: "primary"
            },
            {
                label: I18n.trFor("audioFx", "Secondary color"),
                value: "secondary"
            },
            {
                label: I18n.trFor("audioFx", "Gradient"),
                value: "gradient"
            },
            {
                label: I18n.trFor("audioFx", "Text color"),
                value: "text"
            }
        ]
    }

    SliderSetting {
        settingKey: "fgOpacity"
        label: I18n.trFor("audioFx", "Opacity")
        defaultValue: 50
        minimum: 10
        maximum: 100
        unit: "%"
    }

    SliderSetting {
        settingKey: "bgOpacity"
        label: I18n.trFor("audioFx", "Background opacity")
        description: I18n.trFor("audioFx", "0 leaves the area behind the visualizer clear.")
        defaultValue: 0
        minimum: 0
        maximum: 100
        unit: "%"
    }

    SliderSetting {
        settingKey: "sensitivity"
        label: I18n.trFor("audioFx", "Sensitivity")
        description: I18n.trFor("audioFx", "Fixed gain. Deliberately without cava's automatic sensitivity: it would turn quiet passages up so far that the noise floor flickers.")
        defaultValue: 100
        minimum: 10
        maximum: 300
        unit: "%"
    }

    SliderSetting {
        settingKey: "noiseReduction"
        label: I18n.trFor("audioFx", "Calmness")
        description: I18n.trFor("audioFx", "cava's noise reduction. Low means fast and jittery, high means calm and sluggish. cava's own default is 77.")
        defaultValue: 80
        minimum: 0
        maximum: 100
    }

    SliderSetting {
        settingKey: "frameRate"
        label: I18n.trFor("audioFx", "Frame rate")
        description: I18n.trFor("audioFx", "Costs the most. 30 looks smooth, 20 saves noticeably more.")
        defaultValue: 30
        minimum: 10
        maximum: 60
        unit: "fps"
    }

    ToggleSetting {
        settingKey: "onlyWhilePlaying"
        label: I18n.trFor("audioFx", "Only during playback")
        description: I18n.trFor("audioFx", "Stops cava as soon as no player is playing, instead of just hiding it. Off: cava always runs, but sound without MPRIS is shown too.")
        defaultValue: true
    }

    SliderSetting {
        settingKey: "idleSeconds"
        label: I18n.trFor("audioFx", "Hide after silence")
        defaultValue: 5
        minimum: 1
        maximum: 60
        unit: "s"
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        topPadding: Theme.spacingL
        text: I18n.trFor("audioFx", "Glow in the wallpaper")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        text: I18n.trFor("audioFx", "Glowing spots of the wallpaper pulse to the beat. AudioFX finds the spots itself: saturated, bright pixels in the most common hue of the image. Requires python3 with numpy and Pillow.")
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    ToggleSetting {
        id: glowToggle
        settingKey: "glowOn"
        label: I18n.trFor("audioFx", "Enable glow")
        defaultValue: false
    }

    SelectionSetting {
        id: glowModeSetting
        visible: glowToggle.value
        settingKey: "glowMode"
        label: I18n.trFor("audioFx", "How the spots pulse")
        description: {
            switch (value) {
            case "sync":
                return I18n.trFor("audioFx", "All spots at once, to the bass and volume.");
            case "flow":
                return I18n.trFor("audioFx", "Every bass beat sends a light front through the spots, from the image edge along the streams of light.");
            case "sparkle":
                return I18n.trFor("audioFx", "Every spot flickers at its own rhythm, driven by mids and highs.");
            case "spectrum":
                return I18n.trFor("audioFx", "The image becomes a spectrum: low notes on the left, high notes on the right.");
            default:
                return I18n.trFor("audioFx", "Large spots follow the bass, medium ones the mids, small ones the highs.");
            }
        }
        defaultValue: "bands"
        options: [
            {
                label: I18n.trFor("audioFx", "All at once"),
                value: "sync"
            },
            {
                label: I18n.trFor("audioFx", "By pitch"),
                value: "bands"
            },
            {
                label: I18n.trFor("audioFx", "Flowing"),
                value: "flow"
            },
            {
                label: I18n.trFor("audioFx", "Sparkle"),
                value: "sparkle"
            },
            {
                label: I18n.trFor("audioFx", "Spectrum across the width"),
                value: "spectrum"
            }
        ]
    }

    SliderSetting {
        visible: glowToggle.value
        settingKey: "glowStrength"
        label: I18n.trFor("audioFx", "Glow strength")
        description: I18n.trFor("audioFx", "How brightly the spots themselves light up.")
        defaultValue: 100
        minimum: 10
        maximum: 300
        unit: "%"
    }

    SliderSetting {
        visible: glowToggle.value
        settingKey: "glowBloom"
        label: I18n.trFor("audioFx", "Halo")
        description: I18n.trFor("audioFx", "The soft shine around the spots. 0 lets only the spots themselves glow.")
        defaultValue: 100
        minimum: 0
        maximum: 300
        unit: "%"
    }

    SliderSetting {
        visible: glowToggle.value && glowModeSetting.value === "flow"
        settingKey: "glowSpeed"
        label: I18n.trFor("audioFx", "Light front speed")
        defaultValue: 100
        minimum: 10
        maximum: 300
        unit: "%"
    }

    SelectionSetting {
        visible: glowToggle.value
        settingKey: "glowIdle"
        label: I18n.trFor("audioFx", "Without playback")
        defaultValue: "off"
        options: [
            {
                label: I18n.trFor("audioFx", "Off"),
                value: "off"
            },
            {
                label: I18n.trFor("audioFx", "Glow quietly"),
                value: "glow"
            },
            {
                label: I18n.trFor("audioFx", "Breathe slowly"),
                value: "breathe"
            }
        ]
    }

    SelectionSetting {
        visible: glowToggle.value
        settingKey: "glowColor"
        label: I18n.trFor("audioFx", "Glow color")
        defaultValue: "image"
        options: [
            {
                label: I18n.trFor("audioFx", "From the image"),
                value: "image"
            },
            {
                label: I18n.trFor("audioFx", "Accent"),
                value: "accent"
            }
        ]
    }

    SliderSetting {
        visible: glowToggle.value
        settingKey: "glowThreshold"
        label: I18n.trFor("audioFx", "Detection threshold")
        description: I18n.trFor("audioFx", "Low finds more spots, high only the strongest. After a change the image is analyzed again (about a second).")
        defaultValue: 50
        minimum: 0
        maximum: 100
    }

    SelectionSetting {
        visible: glowToggle.value
        settingKey: "glowColors"
        label: I18n.trFor("audioFx", "Which spots glow")
        description: I18n.trFor("audioFx", "An image with a single glow color is served by its most common color. The third option only falls back to bright light, such as a sun or a light shaft, when an image has no colored spots at all.")
        defaultValue: "hue"
        options: [
            {
                label: I18n.trFor("audioFx", "Most common color"),
                value: "hue"
            },
            {
                label: I18n.trFor("audioFx", "All saturated colors"),
                value: "all"
            },
            {
                label: I18n.trFor("audioFx", "Colors, or bright light if there are none"),
                value: "light"
            }
        ]
    }

    SliderSetting {
        visible: glowToggle.value
        settingKey: "glowFps"
        label: I18n.trFor("audioFx", "Glow frame rate")
        description: I18n.trFor("audioFx", "The glow covers the whole screen, and niri recomposites every frame. 30 is enough for the beat.")
        defaultValue: 30
        minimum: 10
        maximum: 60
        unit: "fps"
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        topPadding: Theme.spacingL
        text: I18n.trFor("audioFx", "Player disc")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "discTurn"
        label: I18n.trFor("audioFx", "Rotation")
        description: I18n.trFor("audioFx", "Seconds per turn, 0 keeps the cover still. Only turns during playback.")
        defaultValue: 90
        minimum: 0
        maximum: 300
        unit: "s"
    }

    StyledText {
        width: parent ? parent.width : implicitWidth
        text: I18n.trFor("audioFx", "The disc is a desktop widget: Settings > Desktop Widgets > Add Desktop Widget > AudioFX. Position, size, grid and workspaces are set there.")
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
    }

    SelectionSetting {
        settingKey: "discForm"
        label: I18n.trFor("audioFx", "Disc visualizer")
        defaultValue: "blob"
        options: [
            {
                label: I18n.trFor("audioFx", "Wave like the dashboard"),
                value: "blob"
            },
            {
                label: I18n.trFor("audioFx", "Bars in a circle"),
                value: "bars"
            },
            {
                label: I18n.trFor("audioFx", "Glow ring"),
                value: "glow"
            }
        ]
    }

    SliderSetting {
        settingKey: "discBars"
        label: I18n.trFor("audioFx", "Number of bars")
        description: I18n.trFor("audioFx", "Only for “Bars in a circle”. More bars get thinner.")
        defaultValue: 72
        minimum: 24
        maximum: 180
    }

    SliderSetting {
        settingKey: "discAmp"
        label: I18n.trFor("audioFx", "Visualizer amplitude")
        description: I18n.trFor("audioFx", "100 % matches the dashboard.")
        defaultValue: 200
        minimum: 50
        maximum: 400
        unit: "%"
    }

    SliderSetting {
        settingKey: "discRing"
        label: I18n.trFor("audioFx", "Progress ring width")
        defaultValue: 4
        minimum: 1
        maximum: 16
        unit: "px"
    }
}
