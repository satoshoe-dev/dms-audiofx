// AudioFX: audio analysis for the glow and the glow ring.
//
// A cava process of its own with 16 bands (low -> high), same principles as
// the visualizer: autosens off, runs only while `active`.
// It computes:
//   bands    16 values 0..1, normalized to the loudest moment of the last few
//            seconds (slowly, so quiet tracks aren't turned up into the noise
//            floor; see the lower bound in process())
//   level    overall level with bass emphasis and beat kick
//   beat     signal on a bass onset, with strength 0..1
//   frame    signal per cava frame (to advance the time)

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Item {
    id: root

    property bool active: false
    property int fps: 30
    property int sensitivity: 100
    property string key: "global"

    property var bands: new Array(16).fill(0)
    property real level: 0
    readonly property bool running: cava.running

    signal beat(real strength)
    signal frame

    property bool cavaAvailable: false
    Process {
        id: cavaCheck
        command: ["sh", "-c", "command -v cava"]
        onExited: exitCode => root.cavaAvailable = exitCode === 0
    }
    Component.onCompleted: cavaCheck.running = true

    readonly property string confPath: `${Paths.strip(StandardPaths.writableLocation(StandardPaths.TempLocation))}/dms-audiofx-levels-${root.key}.conf`
    readonly property string cavaKey: `${fps}:${sensitivity}`
    property bool restarting: false
    onCavaKeyChanged: {
        restarting = true;
        restartTimer.restart();
    }
    Timer {
        id: restartTimer
        interval: 150
        onTriggered: root.restarting = false
    }

    // ------------------------------------------------------------ analysis
    property var _smooth: new Array(16).fill(0)
    property real _peak: 0.4
    property real _bassAvg: 0.1
    property real _kick: 0
    property real _levelSmooth: 0
    property int _cooldown: 0

    function reset() {
        _smooth = new Array(16).fill(0);
        bands = _smooth;
        level = 0;
        _kick = 0;
        _levelSmooth = 0;
    }

    function process(raw) {
        let loudest = 0;
        for (let i = 0; i < raw.length; i++)
            loudest = Math.max(loudest, raw[i]);
        // peak follows quickly upward, decays over ~8 s; 0.22 is the floor
        const decay = Math.pow(0.5, 1 / (8 * fps));
        _peak = Math.max(loudest, _peak * decay, 0.22);

        const s = _smooth.slice();
        let sum = 0;
        for (let i = 0; i < 16; i++) {
            const v = Math.min(1, (raw[i] || 0) / _peak);
            // fast attack, slower release
            s[i] = v > s[i] ? s[i] + (v - s[i]) * 0.7 : s[i] + (v - s[i]) * 0.22;
            sum += s[i];
        }
        _smooth = s;
        bands = s;

        const bass = Math.min(1, ((raw[0] || 0) + (raw[1] || 0) + (raw[2] || 0)) / 3 / _peak);
        // onset: bass clearly above its moving average
        if (_cooldown > 0)
            _cooldown--;
        if (_cooldown === 0 && bass > _bassAvg * 1.35 + 0.08) {
            const strength = Math.max(0.35, Math.min(1, (bass - _bassAvg) * 2.2));
            _kick = Math.max(_kick, strength);
            _cooldown = Math.max(1, Math.round(fps * 0.17));
            root.beat(strength);
        }
        _bassAvg = _bassAvg * 0.92 + bass * 0.08;
        _kick *= Math.pow(0.5, 1 / (0.12 * fps));

        const target = bass * 0.6 + (sum / 16) * 0.4;
        _levelSmooth += (target - _levelSmooth) * (target > _levelSmooth ? 0.6 : 0.2);
        level = Math.min(1.5, _levelSmooth * 0.85 + _kick * 0.55);
        root.frame();
    }

    Process {
        id: cava
        running: root.active && root.cavaAvailable && !root.restarting
        command: ["sh", "-c", `cat <<'CAVACONF' > ${root.confPath}
[general]
framerate=${root.fps}
bars=16
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
noise_reduction=45
monstercat=0
CAVACONF
exec cava -p ${root.confPath} < /dev/null`]

        onRunningChanged: {
            if (!running)
                root.reset();
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!root.active || !data)
                    return;
                const parts = data.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++) {
                    const n = parseInt(parts[i], 10);
                    if (!isNaN(n))
                        out.push(Math.min(1, n / 1000));
                }
                if (out.length >= 16)
                    root.process(out);
            }
        }
    }
}
