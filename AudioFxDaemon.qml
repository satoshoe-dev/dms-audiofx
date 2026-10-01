// AudioFX: the window.
//
// Why a window of its own instead of a DMS desktop widget:
// Since niri 25.05 the `background` and `bottom` layers are attached to
// workspaces and move along when switching. A surface can only be taken out
// with the niri rule `place-within-backdrop`, and that applies only to
// `background` surfaces that ignore exclusive zones. DMS, however, puts
// desktop widgets on `bottom` (or `overlay`, where they sit in front of
// windows). Measured: bottom moves along, overlay doesn't, but overlay covers
// the windows.
// This window therefore sits on `background`; it needs a matching niri rule
// (layer-rule with match namespace="^audiofx$" and place-within-backdrop).
// The DMS wallpaper (^quickshell$) usually lives in the backdrop already, so
// the visualizer ends up in the same static backdrop.
//
// Margins: not guessed but computed from the DMS values. The frame is
// `frameThickness` thick; on the side where the bar is attached it is
// `frameBarSize` instead. If the frame or bar position changes, e.g. through a
// profile switch, the visualizer follows by itself.

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services

Item {
    id: daemon

    // set by the plugin loader
    property var pluginService: null
    property string pluginId: "audioFx"

    readonly property var _t: SettingsData.pluginSettings

    function cfg(key, fallback) {
        return SettingsData.getPluginSetting("audioFx", key, fallback);
    }

    readonly property string edge: {
        daemon._t;
        return cfg("edge", "bottom");
    }
    readonly property int depth: {
        daemon._t;
        return Math.max(20, Math.min(600, cfg("depth", 160)));
    }
    readonly property bool switchedOn: {
        daemon._t;
        return cfg("on", true);
    }
    // Extra inset at both ends along the edge, beyond frame and bar. Only
    // applies along the edge; the depth is controlled by `depth`.
    readonly property int sideInset: {
        daemon._t;
        return Math.max(0, Math.min(800, cfg("sideInset", 0)));
    }

    readonly property bool horizontalEdge: edge === "bottom" || edge === "top"

    // ---------------------------------------------------------------- margins
    readonly property int frameInset: SettingsData.frameEnabled ? SettingsData.frameThickness : 0

    // Side the bar is attached to (DMS position: 0 top, 1 bottom, 2 left, 3 right)
    readonly property string barSide: {
        const configs = SettingsData.barConfigs ?? [];
        for (let i = 0; i < configs.length; i++) {
            if (!configs[i].enabled)
                continue;
            switch (configs[i].position) {
            case 0:
                return "top";
            case 1:
                return "bottom";
            case 2:
                return "left";
            case 3:
                return "right";
            }
        }
        return "";
    }

    function inset(side) {
        if (side === daemon.barSide && SettingsData.frameEnabled)
            return Math.max(daemon.frameInset, SettingsData.frameBarSize);
        return daemon.frameInset;
    }

    // The player disc is a DMS desktop widget (AudioFxDiscDesktop.qml), it has
    // no windows here.

    // ---------------------------------------------------------------- glow
    // Glowing spots of the wallpaper pulse to the beat (AudioFxGlow.qml). A
    // full-screen surface of its own, also on `background` in the backdrop
    // (niri rule ^audiofx-glow$), without input. Created before the visualizer
    // window so waves and bars lie above it.
    readonly property bool glowOn: {
        daemon._t;
        return cfg("glowOn", false);
    }

    // The surface stays created even when switched off (empty, draws nothing):
    // niri stacks surfaces of the same layer in creation order. Created only
    // when switched on at runtime, the glow would end up above the desktop
    // widgets instead of below them.
    // One cava process for the glow on every screen. It runs while the glow
    // is ready on at least one screen (wallpaper analyzed, textures loaded)
    // and something plays.
    readonly property bool glowReady: glowScreens.instances.some(w => w.glowReady)
    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false

    AudioFxLevels {
        id: glowLevels
        active: daemon.glowReady && daemon.playing
        fps: {
            daemon._t;
            return Math.max(10, Math.min(60, daemon.cfg("glowFps", 30)));
        }
        sensitivity: {
            daemon._t;
            return Math.max(10, Math.min(300, daemon.cfg("sensitivity", 100)));
        }
        key: "glow"
    }

    Variants {
        id: glowScreens

        model: Quickshell.screens

        delegate: PanelWindow {
            id: glowWindow

            required property var modelData

            screen: glowWindow.modelData
            color: "transparent"

            WlrLayershell.namespace: "audiofx-glow"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            mask: Region {
                item: Item {}
            }

            readonly property bool glowReady: glow.ready

            AudioFxGlow {
                id: glow
                anchors.fill: parent
                screenName: glowWindow.modelData?.name ?? ""
                levels: glowLevels
            }
        }
    }

    // ---------------------------------------------------------------- IPC
    // dms ipc call audiofx glow on|off|toggle
    // dms ipc call audiofx mode sync|bands|flow|sparkle|spectrum
    // dms ipc call audiofx set <key> <value>   (numbers and true/false are converted)
    // dms ipc call audiofx get <key>
    IpcHandler {
        target: "audiofx"

        function glow(state: string): string {
            const on = state === "toggle" ? !daemon.glowOn : (state === "on" || state === "true" || state === "1");
            SettingsData.setPluginSetting("audioFx", "glowOn", on);
            return on ? "Glow on" : "Glow off";
        }

        function mode(m: string): string {
            const allowed = ["sync", "bands", "flow", "sparkle", "spectrum"];
            if (allowed.indexOf(m) < 0)
                return "unknown, allowed: " + allowed.join(", ");
            SettingsData.setPluginSetting("audioFx", "glowMode", m);
            return "mode " + m;
        }

        function set(key: string, value: string): string {
            let v = value;
            if (value === "true" || value === "false")
                v = value === "true";
            else if (value !== "" && !isNaN(Number(value)))
                v = Number(value);
            SettingsData.setPluginSetting("audioFx", key, v);
            return key + " = " + JSON.stringify(v);
        }

        function get(key: string): string {
            return JSON.stringify(daemon.cfg(key, null));
        }
    }

    // One cava process for the visualizer on every screen
    AudioFxBands {
        id: bandSource
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: visualizerWindow

            required property var modelData

            screen: visualizerWindow.modelData
            visible: daemon.switchedOn
            color: "transparent"

            WlrLayershell.namespace: "audiofx"
            // background instead of bottom: only then does place-within-backdrop apply.
            WlrLayershell.layer: WlrLayer.Background
            // Required for the backdrop, and needed so we set the margins
            // ourselves instead of getting them from the compositor.
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                left: daemon.horizontalEdge || daemon.edge === "left"
                right: daemon.horizontalEdge || daemon.edge === "right"
                top: !daemon.horizontalEdge || daemon.edge === "top"
                bottom: !daemon.horizontalEdge || daemon.edge === "bottom"
            }

            margins {
                left: daemon.inset("left") + (daemon.horizontalEdge ? daemon.sideInset : 0)
                right: daemon.inset("right") + (daemon.horizontalEdge ? daemon.sideInset : 0)
                top: daemon.inset("top") + (daemon.horizontalEdge ? 0 : daemon.sideInset)
                bottom: daemon.inset("bottom") + (daemon.horizontalEdge ? 0 : daemon.sideInset)
            }

            implicitHeight: daemon.horizontalEdge ? daemon.depth : 0
            implicitWidth: daemon.horizontalEdge ? 0 : daemon.depth

            AudioFxCanvas {
                anchors.fill: parent
                source: bandSource
            }
        }
    }
}
