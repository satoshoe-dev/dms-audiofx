// AudioFX: circular bars around the cover of the player disc.
//
// Second style next to the blob. DMS' CavaService only provides 6 bands, too
// few for a bar wreath, hence a cava process of its own like in the visualizer
// (AudioFxCanvas), with the same principles: autosens off, runs only while
// the bars are actually visible and something is playing.
//
// Half of the bars come from cava (low frequencies at the top), the other
// half is mirrored, so the wreath looks the same left and right.

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    // set from outside
    property bool active: false
    property bool playing: false
    property real coverSize: 260
    property real amplitude: 2.0
    property int barCount: 72
    property string windowKey: "global"

    readonly property int halfCount: Math.max(6, Math.round(barCount / 2))
    readonly property real innerRadius: coverSize / 2 + 5
    readonly property real maxLength: coverSize * 0.09 * amplitude
    readonly property bool wantsData: active && playing && cavaAvailable

    property var levels: []
    property bool cavaAvailable: false

    // fade out once nothing comes in anymore
    // strength: opacity chosen in the settings, the fade stays in charge
    property real strength: 1
    opacity: wantsData ? strength : 0
    Behavior on opacity {
        NumberAnimation {
            duration: 400
        }
    }

    Process {
        id: cavaCheck
        command: ["sh", "-c", "command -v cava"]
        onExited: exitCode => root.cavaAvailable = exitCode === 0
    }
    Component.onCompleted: cavaCheck.running = true

    readonly property string confPath: `${Paths.strip(StandardPaths.writableLocation(StandardPaths.TempLocation))}/dms-audiofx-disc-${root.windowKey}.conf`
    readonly property string cavaKey: `${halfCount}`
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

    Process {
        id: wreathCava
        running: root.wantsData && !root.restarting
        // StandardPaths needs `import QtCore`; without it confPath is empty and
        // the shell command fails silently
        command: ["sh", "-c", `cat <<'CAVACONF' > ${root.confPath}
[general]
framerate=30
bars=${root.halfCount}
autosens=0
sensitivity=100

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
noise_reduction=75
monstercat=1.2
CAVACONF
exec cava -p ${root.confPath} < /dev/null`]

        onRunningChanged: {
            if (!running) {
                root.levels = [];
                barCanvas.requestPaint();
            }
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (!root.wantsData || !data)
                    return;
                const parts = data.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++) {
                    const n = parseInt(parts[i], 10);
                    if (!isNaN(n))
                        out.push(Math.min(1, n / 1000));
                }
                if (out.length === 0)
                    return;
                root.levels = out;
                barCanvas.requestPaint();
            }
        }
    }

    Canvas {
        id: barCanvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const values = root.levels;
            const n = root.halfCount;
            if (!values || values.length === 0)
                return;
            const cx = width / 2;
            const cy = height / 2;
            const total = n * 2;
            const circumference = 2 * Math.PI * root.innerRadius;
            const thickness = Math.max(1.5, Math.min(8, circumference / total * 0.55));
            ctx.lineCap = "round";
            ctx.lineWidth = thickness;
            ctx.strokeStyle = Theme.primary;
            for (let i = 0; i < total; i++) {
                // 0 = top, clockwise; second half mirrored
                const band = i < n ? i : total - 1 - i;
                const v = values[Math.min(band, values.length - 1)] || 0;
                const length = 1 + v * root.maxLength;
                const angle = -Math.PI / 2 + (i + 0.5) / total * 2 * Math.PI;
                const cos = Math.cos(angle);
                const sin = Math.sin(angle);
                ctx.globalAlpha = 0.55 + 0.45 * v;
                ctx.beginPath();
                ctx.moveTo(cx + cos * root.innerRadius, cy + sin * root.innerRadius);
                ctx.lineTo(cx + cos * (root.innerRadius + length), cy + sin * (root.innerRadius + length));
                ctx.stroke();
            }
        }
    }
}
