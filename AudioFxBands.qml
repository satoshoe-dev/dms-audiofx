// AudioFX: the band values for the visualizer.
//
// Created once by AudioFxDaemon.qml and handed to the AudioFxCanvas on every
// screen, so there is one cava process however many screens there are.
//
// The cava process only runs while something is actually visible: visualizer
// on and (optionally) an MPRIS player playing. That is the difference from the
// ready-made visualizers in the registry, which keep cava running and merely
// hide the output.

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    visible: false

    readonly property var _t: SettingsData.pluginSettings

    function cfg(key, fallback) {
        return SettingsData.getPluginSetting("audioFx", key, fallback);
    }

    readonly property bool switchedOn: {
        root._t;
        return cfg("on", true);
    }
    readonly property int bands: {
        root._t;
        return Math.max(4, Math.min(128, cfg("bands", 48)));
    }
    readonly property int frameRate: {
        root._t;
        return Math.max(10, Math.min(60, cfg("frameRate", 30)));
    }
    readonly property int sensitivity: {
        root._t;
        return Math.max(10, Math.min(300, cfg("sensitivity", 100)));
    }
    // cava: int 0-100, cava's default is 77. Controls the integral and gravity
    // filters together; low means fast and jittery, high means sluggish and
    // calm. DMS uses 35 here, but also sets integral/gravity/ignore by hand;
    // without those, 35 is almost unfiltered and the curve flickers.
    readonly property int noiseReduction: {
        root._t;
        return Math.max(0, Math.min(100, cfg("noiseReduction", 80)));
    }
    readonly property bool onlyWhilePlaying: {
        root._t;
        return cfg("onlyWhilePlaying", true);
    }

    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false
    readonly property bool wantsData: switchedOn && cavaAvailable && (!onlyWhilePlaying || playing)

    property var levels: []
    property bool silent: true

    // ---------------------------------------------------------------- cava
    property bool cavaAvailable: false
    property bool rebuilding: false

    readonly property string confPath: `${Paths.strip(StandardPaths.writableLocation(StandardPaths.TempLocation))}/dms-audiofx.conf`

    // If one of these values changes, cava must restart with a new config.
    readonly property string cavaKey: `${bands}:${frameRate}:${sensitivity}:${noiseReduction}`
    onCavaKeyChanged: {
        rebuilding = true;
        rebuildTimer.restart();
    }

    Timer {
        id: rebuildTimer
        interval: 150
        repeat: false
        onTriggered: root.rebuilding = false
    }

    Process {
        id: cavaCheck
        command: ["sh", "-c", "command -v cava"]
        running: false
        onExited: exitCode => root.cavaAvailable = exitCode === 0
    }

    Component.onCompleted: cavaCheck.running = true

    Process {
        id: cavaProcess

        // autosens MUST stay off: with automatic sensitivity cava turns up the
        // gain in quiet passages until the noise floor produces full swings, and
        // the curve flickers instead of moving gently. DMS does the same in its
        // CavaService.
        running: root.wantsData && !root.rebuilding
        command: ["sh", "-c", `cat <<'CAVACONF' > ${root.confPath}
[general]
framerate=${root.frameRate}
bars=${root.bands}
autosens=0
sensitivity=${root.sensitivity}

[output]
method=raw
raw_target=/dev/stdout
data_format=ascii
ascii_max_range=1000
bar_delimiter=59
frame_delimiter=10
channels=mono
mono_option=average

[smoothing]
noise_reduction=${root.noiseReduction}
monstercat=1.5
CAVACONF
exec cava -p ${root.confPath} < /dev/null`]

        onRunningChanged: {
            if (!running) {
                root.levels = new Array(root.bands).fill(0);
                root.silent = true;
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!root.wantsData || !data || data.length === 0)
                    return;
                const parts = data.split(";");
                const out = [];
                let quiet = true;
                for (let i = 0; i < parts.length; i++) {
                    const n = parseInt(parts[i], 10);
                    if (isNaN(n))
                        continue;
                    const v = Math.min(1, n / 1000);
                    out.push(v);
                    if (v > 0.01)
                        quiet = false;
                }
                if (out.length === 0)
                    return;
                root.levels = out;
                root.silent = quiet;
            }
        }
    }
}
