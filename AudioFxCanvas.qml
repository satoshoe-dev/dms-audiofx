// AudioFX: the drawing surface. AudioFxDaemon.qml puts it into a window of its
// own (see there for why it is not a DMS desktop widget).
//
// Bar shapes are drawn by a Repeater of rectangles (cheap, only geometry
// changes). Wave shapes are drawn by QtQuick.Shapes from a polyline; the soft
// curves come from Catmull-Rom interpolation between the band values, not
// from a Canvas, which would have to rasterize every frame and upload it as a
// texture.
//
// Edges: drawing always happens in "bottom" orientation into an inner item of
// size (length x depth). For the other three edges that item is mirrored or
// rotated, so the drawing logic exists only once.
//
// The cava process only runs while something is actually visible: visualizer
// on and (optionally) an MPRIS player playing. That is the difference from the
// ready-made visualizers in the registry, which keep cava running and merely
// hide the output.

pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    // Distinguishes the cava config file per screen.
    property string windowKey: "global"

    // ---------------------------------------------------------------- settings
    // Everything lives in the plugin settings. pluginSettings is reassigned as a
    // whole on every write; the dependency on _t makes the bindings reactive,
    // so no change needs a restart.
    readonly property var _t: SettingsData.pluginSettings

    function cfg(key, fallback) {
        return SettingsData.getPluginSetting("audioFx", key, fallback);
    }

    readonly property bool switchedOn: {
        root._t;
        return cfg("on", true);
    }
    readonly property string form: {
        root._t;
        return cfg("form", "waveFilled");
    }
    readonly property string edge: {
        root._t;
        return cfg("edge", "bottom");
    }
    readonly property int bands: {
        root._t;
        return Math.max(4, Math.min(128, cfg("bands", 48)));
    }
    readonly property int frameRate: {
        root._t;
        return Math.max(10, Math.min(60, cfg("frameRate", 30)));
    }
    readonly property int gap: {
        root._t;
        return cfg("gap", 4);
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
    readonly property real fgAlpha: {
        root._t;
        return cfg("fgOpacity", 50) / 100;
    }
    readonly property real bgAlpha: {
        root._t;
        return cfg("bgOpacity", 0) / 100;
    }
    readonly property string colorChoice: {
        root._t;
        return cfg("colorChoice", "primary");
    }
    readonly property bool onlyWhilePlaying: {
        root._t;
        return cfg("onlyWhilePlaying", true);
    }
    readonly property int idleSeconds: {
        root._t;
        return cfg("idleSeconds", 5);
    }
    readonly property int segments: {
        root._t;
        return Math.max(4, Math.min(30, cfg("segments", 12)));
    }
    readonly property int lineWidth: {
        root._t;
        return Math.max(1, Math.min(12, cfg("lineWidth", 3)));
    }
    readonly property int smoothing: {
        root._t;
        return Math.max(1, Math.min(12, cfg("smoothing", 8)));
    }
    // Does the wave taper off to the baseline at both ends instead of ending
    // abruptly at the edge?
    readonly property bool taper: {
        root._t;
        return cfg("taper", true);
    }
    // Share of the length per side over which the wave is faded down.
    readonly property int taperWidth: {
        root._t;
        return Math.max(1, Math.min(45, cfg("taperWidth", 15)));
    }

    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false
    readonly property bool wantsData: switchedOn && cavaAvailable && (!onlyWhilePlaying || playing)

    // ---------------------------------------------------------------- orientation
    readonly property bool horizontalEdge: edge === "bottom" || edge === "top"
    // Length along the edge, depth perpendicular to it.
    readonly property real along: horizontalEdge ? width : height
    readonly property real deep: horizontalEdge ? height : width

    // ---------------------------------------------------------------- colors
    readonly property color baseColor: {
        if (colorChoice === "secondary")
            return Theme.secondary;
        if (colorChoice === "text")
            return Theme.surfaceVariantText;
        return Theme.primary;
    }
    readonly property bool gradientOn: colorChoice === "gradient"
    // Computed once instead of per bar and frame, which is what makes a cava
    // visualizer expensive.
    readonly property color fillColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, fgAlpha)
    readonly property color gradTop: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, fgAlpha)
    readonly property color gradBottom: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, fgAlpha)

    // ---------------------------------------------------------------- state
    property var levels: []
    property bool silent: true
    property bool faded: true

    readonly property bool barLike: ["bars", "barsMirrored", "barsInverted", "blocks", "dots"].indexOf(form) >= 0
    readonly property bool waveLike: ["wave", "waveFilled", "waveMirrored"].indexOf(form) >= 0
    // The bars get the same gap at both ends as between each other, otherwise
    // the outermost ones stick to the edge. So one gap is subtracted from the
    // length and the whole row is shifted inward by half a gap: that leaves
    // exactly `gap` free on the left and on the right.
    readonly property real slot: bands > 0 ? Math.max(1, (along - gap) / bands) : 0
    readonly property real barW: Math.max(1, slot - gap)

    opacity: (!switchedOn || faded) ? 0 : 1
    Behavior on opacity {
        NumberAnimation {
            duration: 700
            easing.type: Easing.InOutQuad
        }
    }

    onSilentChanged: {
        if (silent) {
            idleTimer.restart();
        } else {
            idleTimer.stop();
            faded = false;
        }
    }

    onWantsDataChanged: {
        if (!wantsData)
            faded = true;
    }

    Timer {
        id: idleTimer
        interval: Math.max(1, root.idleSeconds) * 1000
        repeat: false
        onTriggered: root.faded = true
    }

    // ---------------------------------------------------------------- cava
    property bool cavaAvailable: false
    property bool rebuilding: false

    readonly property string confPath: `${Paths.strip(StandardPaths.writableLocation(StandardPaths.TempLocation))}/dms-audiofx-${root.windowKey}.conf`

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

    // ---------------------------------------------------------------- wave points
    property var wavePoints: []

    // Catmull-Rom: lays a smooth curve through all knots (unlike Bezier, which
    // only pulls toward them). `steps` sets how many intermediate points each
    // segment gets.
    function spline(pts, steps) {
        if (pts.length < 3 || steps < 2)
            return pts;
        const out = [];
        for (let i = 0; i < pts.length - 1; i++) {
            const p0 = pts[Math.max(0, i - 1)];
            const p1 = pts[i];
            const p2 = pts[i + 1];
            const p3 = pts[Math.min(pts.length - 1, i + 2)];
            for (let s = 0; s < steps; s++) {
                const t = s / steps;
                const t2 = t * t;
                const t3 = t2 * t;
                const x = 0.5 * (2 * p1.x + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3);
                const y = 0.5 * (2 * p1.y + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);
                out.push(Qt.point(x, y));
            }
        }
        out.push(pts[pts.length - 1]);
        return out;
    }

    // Raised-cosine (Tukey) window: 1 in the middle, softly down to 0 toward
    // both ends. A single zero point at the edge is not enough: the outermost
    // band value would still stand at full height right next to it and the
    // curve would drop steeply. The window lowers the amplitudes themselves
    // over a stretch instead.
    function taperWindow(i, n) {
        if (!taper)
            return 1;
        const k = Math.max(1, Math.round(n * taperWidth / 100));
        if (i < k)
            return 0.5 - 0.5 * Math.cos(Math.PI * (i + 0.5) / k);
        if (i >= n - k)
            return 0.5 - 0.5 * Math.cos(Math.PI * (n - i - 0.5) / k);
        return 1;
    }

    // Remove consecutive identical points. Duplicate corners make zero-length
    // edges, which the curve renderer triangulates differently from frame to
    // frame, visible as flicker.
    function dedup(pts) {
        const out = [];
        for (let i = 0; i < pts.length; i++) {
            const p = pts[i];
            const v = out.length ? out[out.length - 1] : null;
            if (v && Math.abs(v.x - p.x) < 0.01 && Math.abs(v.y - p.y) < 0.01)
                continue;
            out.push(p);
        }
        return out;
    }

    function rebuildWave() {
        const L = along;
        const D = deep;
        if (!waveLike || L <= 0 || D <= 0 || levels.length < 2) {
            wavePoints = [];
            return;
        }
        const n = levels.length;
        const mirrored = form === "waveMirrored";
        const mid = D / 2;

        // Minimum height of the area. Without it the top edge lies exactly on
        // the baseline in the taper stretch, the polygon has no area there and
        // the renderer triangulates it inconsistently, which flickers in quiet
        // passages. The thin plinth also looks better than tapering to exactly
        // zero.
        const plinth = Math.max(1.5, D * 0.012);
        const swing = Math.max(1, (mirrored ? mid : D) - plinth);

        // With tapering, the band values sit between two zero points at the
        // ends, so the curve rises from the plinth and returns to it instead of
        // ending abruptly at the edge.
        const margin = taper ? slot / 2 : 0;
        const usable = Math.max(1, L - 2 * margin);

        function xAt(i) {
            return margin + (n === 1 ? usable / 2 : i * (usable / (n - 1)));
        }
        function levelAt(i) {
            return (levels[i] ?? 0) * taperWindow(i, n);
        }

        const knots = [];
        if (taper)
            knots.push(Qt.point(0, mirrored ? mid - plinth / 2 : D - plinth));
        for (let i = 0; i < n; i++) {
            const v = levelAt(i);
            knots.push(Qt.point(xAt(i), mirrored ? mid - plinth / 2 - v * swing : D - plinth - v * swing));
        }
        if (taper)
            knots.push(Qt.point(L, mirrored ? mid - plinth / 2 : D - plinth));

        const top = dedup(spline(knots, root.smoothing));

        if (form === "wave") {
            wavePoints = top;
            return;
        }

        if (form === "waveFilled") {
            // The bottom corners close the area. They always lie below the
            // curve, because the curve never goes lower than the plinth.
            wavePoints = dedup(top.concat([Qt.point(L, D), Qt.point(0, D)]));
            return;
        }

        // waveMirrored: along the top, back along the bottom, forming a closed band
        const bottomKnots = [];
        if (taper)
            bottomKnots.push(Qt.point(L, mid + plinth / 2));
        for (let i = n - 1; i >= 0; i--) {
            const v = levelAt(i);
            bottomKnots.push(Qt.point(xAt(i), mid + plinth / 2 + v * swing));
        }
        if (taper)
            bottomKnots.push(Qt.point(0, mid + plinth / 2));

        wavePoints = dedup(top.concat(spline(bottomKnots, root.smoothing)));
    }

    onLevelsChanged: rebuildWave()
    onAlongChanged: rebuildWave()
    onDeepChanged: rebuildWave()
    onFormChanged: rebuildWave()
    onSmoothingChanged: rebuildWave()
    onTaperChanged: rebuildWave()

    // ---------------------------------------------------------------- canvas
    // Always drawn in "bottom" orientation and then turned to the chosen edge.
    // The transforms apply in list order: mirror first (for top), then rotate
    // (for left/right).
    Item {
        id: canvas

        width: root.along
        height: root.deep
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        transform: [
            Scale {
                origin.x: canvas.width / 2
                origin.y: canvas.height / 2
                yScale: root.edge === "top" ? -1 : 1
            },
            Rotation {
                origin.x: canvas.width / 2
                origin.y: canvas.height / 2
                angle: root.edge === "left" ? 90 : root.edge === "right" ? -90 : 0
            }
        ]

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            opacity: root.bgAlpha
            radius: Theme.cornerRadius
            visible: root.bgAlpha > 0
        }

        // ------------------------------------------------------------ bar shapes
        Item {
            anchors.fill: parent
            visible: root.barLike

            Repeater {
                model: root.barLike ? root.bands : 0

                delegate: Item {
                    id: slotItem

                    required property int index
                    readonly property real norm: root.levels[slotItem.index] ?? 0
                    readonly property real dotSize: Math.max(2, Math.min(root.barW, 14))

                    x: root.gap / 2 + slotItem.index * root.slot
                    y: 0
                    width: root.slot
                    height: canvas.height

                    // --- dot: sits at the level height ---
                    Rectangle {
                        visible: root.form === "dots"
                        width: slotItem.dotSize
                        height: width
                        radius: width / 2
                        x: (slotItem.width - width) / 2
                        y: Math.max(0, slotItem.height - slotItem.norm * slotItem.height - height)
                        color: root.fillColor
                    }

                    // --- blocks: the bar is built from lit segments, not from
                    //     one bar with gaps. Over a transparent background
                    //     nothing can be cut away: a strip on top would be one
                    //     more color, not a gap.
                    Repeater {
                        model: root.form === "blocks" ? root.segments : 0

                        delegate: Rectangle {
                            required property int index
                            readonly property real step: slotItem.height / root.segments

                            visible: slotItem.norm * root.segments > index
                            width: root.barW
                            x: (slotItem.width - width) / 2
                            height: Math.max(1, step * 0.72)
                            y: slotItem.height - (index + 1) * step
                            radius: Math.min(width / 2, 3)
                            color: root.fillColor
                        }
                    }

                    // --- bar: standing, hanging or mirrored around the middle ---
                    Rectangle {
                        id: bar

                        visible: root.form !== "dots" && root.form !== "blocks"
                        width: root.barW
                        x: (slotItem.width - width) / 2
                        height: Math.max(2, slotItem.norm * slotItem.height)
                        y: root.form === "barsInverted" ? 0 : root.form === "barsMirrored" ? (slotItem.height - height) / 2 : slotItem.height - height
                        radius: Math.min(width / 2, 4)
                        color: root.gradientOn ? "transparent" : root.fillColor

                        gradient: root.gradientOn ? barGradient : null

                        Gradient {
                            id: barGradient
                            orientation: Gradient.Vertical
                            GradientStop {
                                position: 0
                                color: root.gradTop
                            }
                            GradientStop {
                                position: 1
                                color: root.gradBottom
                            }
                        }
                    }
                }
            }
        }

        // ------------------------------------------------------------ wave shapes
        Shape {
            anchors.fill: parent
            visible: root.waveLike && root.wavePoints.length > 1
            // CurveRenderer instead of GeometryRenderer: it antialiases edges on
            // the GPU. Invisible on bars, but a slanted curve edge otherwise
            // looks jagged. Costs about 2.5 percentage points of CPU (measured).
            preferredRendererType: Shape.CurveRenderer
            antialiasing: true

            ShapePath {
                strokeColor: root.form === "wave" ? root.fillColor : "transparent"
                strokeWidth: root.form === "wave" ? root.lineWidth : 0
                fillColor: root.form === "wave" ? "transparent" : root.fillColor
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                fillGradient: (root.gradientOn && root.form !== "wave") ? waveGradient : null

                PathPolyline {
                    path: root.wavePoints
                }
            }

            LinearGradient {
                id: waveGradient
                x1: 0
                y1: 0
                x2: 0
                y2: canvas.height
                GradientStop {
                    position: 0
                    color: root.gradTop
                }
                GradientStop {
                    position: 1
                    color: root.gradBottom
                }
            }
        }
    }
}
