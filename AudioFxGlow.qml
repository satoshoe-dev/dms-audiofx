// AudioFX: glowing spots of the wallpaper pulse to the beat.
//
// Pipeline:
//   1. audiofx-glow.py finds the glowing spots in the current wallpaper and
//      stores core, info and distance textures in ~/.cache (once per image and
//      setting, from the cache afterwards).
//   2. shaders/glow.frag draws only light on top (additive, alpha 0) into a
//      full-screen surface on `background` in the niri backdrop, directly
//      above the DMS wallpaper.
//   3. AudioFxLevels provides bands, level and beats.
//
// Cost: the shader only renders when a value changes, i.e. at the cava frame
// rate, at 15 frames per second for "breathe", and not at all for "glow" and
// "off" idle modes. Everywhere outside the glow spots it bails out at once.
//
// Geometry: like DMS (WallpaperBackground.qml, calculateUV) for stretch, fit
// and fill; tile and scroll are treated like fill.

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    property string screenName: ""

    readonly property var _t: SettingsData.pluginSettings
    function cfg(key, fallback) {
        return SettingsData.getPluginSetting("audioFx", key, fallback);
    }

    readonly property bool switchedOn: {
        root._t;
        return cfg("glowOn", false);
    }
    readonly property string mode: {
        root._t;
        return cfg("glowMode", "bands");
    }
    readonly property real strength: {
        root._t;
        return Math.max(10, Math.min(300, cfg("glowStrength", 100))) / 100;
    }
    readonly property real bloomStrength: {
        root._t;
        return Math.max(0, Math.min(300, cfg("glowBloom", 100))) / 100;
    }
    readonly property int threshold: {
        root._t;
        return Math.max(0, Math.min(100, cfg("glowThreshold", 50)));
    }
    readonly property string colorChoice: {
        root._t;
        return cfg("glowColor", "image");
    }
    // hue: the most common saturated color, all: every saturated color,
    // light: saturated colors plus bright light sources without color
    readonly property string colorsMode: {
        root._t;
        return cfg("glowColors", cfg("glowAllHues", false) ? "all" : "hue");
    }
    readonly property string idleMode: {
        root._t;
        return cfg("glowIdle", "off");
    }
    readonly property real speed: {
        root._t;
        return Math.max(10, Math.min(300, cfg("glowSpeed", 100))) / 100 * 0.45;
    }
    readonly property int fps: {
        root._t;
        return Math.max(10, Math.min(60, cfg("glowFps", 30)));
    }
    readonly property int sensitivity: {
        root._t;
        return Math.max(10, Math.min(300, cfg("sensitivity", 100)));
    }

    // ------------------------------------------------------------ wallpaper
    readonly property string imagePath: {
        const p = SessionData.getMonitorWallpaper(root.screenName) || "";
        return p.startsWith("file://") ? decodeURIComponent(p.substring(7)) : p;
    }
    // a wallpaper starting with "#" is a solid color, nothing to analyze
    readonly property bool imageUsable: imagePath !== "" && !imagePath.startsWith("#")
    readonly property int fillMode: {
        const m = Theme.getFillMode(SessionData.getMonitorWallpaperFillMode(root.screenName));
        if (m === Image.Stretch)
            return 0;
        if (m === Image.PreserveAspectFit)
            return 1;
        return 2;
    }

    property var mask: null
    property string error: ""

    readonly property string script: Qt.resolvedUrl("audiofx-glow.py").toString().replace(/^file:\/\//, "")
    readonly property string maskKey: `${imagePath}|${threshold}|${colorsMode}`

    // Drop the old mask right away. Otherwise the spots of the previous wallpaper
    // glow on the new one until the new analysis is done (a few seconds).
    onMaskKeyChanged: {
        root.mask = null;
        maskTimer.restart();
    }
    onSwitchedOnChanged: maskTimer.restart()
    Component.onCompleted: maskTimer.restart()

    Timer {
        id: maskTimer
        interval: 400
        onTriggered: {
            if (!root.switchedOn || !root.imageUsable)
                return;
            maskProcess.running = false;
            maskProcess.output = "";
            maskProcess.requestedKey = root.maskKey;
            maskProcess.command = ["python3", root.script, root.imagePath, "--threshold", String(root.threshold), "--colors", root.colorsMode];
            maskProcess.running = true;
        }
    }

    Process {
        id: maskProcess
        property string output: ""
        property string errorText: ""
        property string requestedKey: ""
        stdout: SplitParser {
            onRead: data => maskProcess.output += data
        }
        stderr: SplitParser {
            onRead: data => maskProcess.errorText += data + "\n"
        }
        onExited: code => {
            if (code !== 0) {
                root.error = maskProcess.errorText.trim().split("\n").pop() || ("audiofx-glow.py exited with " + code);
                console.warn("AudioFX Glow:", root.error);
                maskProcess.errorText = "";
                return;
            }
            if (maskProcess.requestedKey !== root.maskKey)
                return;
            try {
                root.mask = JSON.parse(maskProcess.output);
                root.error = "";
            } catch (e) {
                root.error = "unreadable output: " + maskProcess.output;
                console.warn("AudioFX Glow:", root.error);
            }
        }
    }

    // ------------------------------------------------------------ audio
    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false
    readonly property bool ready: switchedOn && mask !== null && coreImage.status === Image.Ready && infoImage.status === Image.Ready && distImage.status === Image.Ready && colorImage.status === Image.Ready

    AudioFxLevels {
        id: audio
        active: root.ready && root.playing
        fps: root.fps
        sensitivity: root.sensitivity
        key: "glow-" + root.screenName

        onFrame: effect.time = root.now()
        onBeat: strength => {
            const times = [effect.beatTime.x, effect.beatTime.y, effect.beatTime.z, effect.beatTime.w];
            const strengths = [effect.beatStrength.x, effect.beatStrength.y, effect.beatStrength.z, effect.beatStrength.w];
            // replace the oldest slot
            let oldest = 0;
            for (let i = 1; i < 4; i++)
                if (times[i] < times[oldest])
                    oldest = i;
            times[oldest] = root.now();
            strengths[oldest] = strength;
            effect.beatTime = Qt.vector4d(times[0], times[1], times[2], times[3]);
            effect.beatStrength = Qt.vector4d(strengths[0], strengths[1], strengths[2], strengths[3]);
        }
    }

    readonly property real _start: Date.now()
    function now() {
        // keep numbers small, the shader works in float
        return ((Date.now() - _start) / 1000) % 3600;
    }

    // base glow: only without playback
    property real breath: 0
    readonly property real idle: {
        if (audio.running)
            return 0;
        if (idleMode === "glow")
            return 0.18;
        if (idleMode === "breathe")
            return breath;
        return 0;
    }
    Timer {
        running: root.ready && !audio.running && root.idleMode === "breathe" && effect.visible
        interval: 66
        repeat: true
        onTriggered: {
            const t = root.now();
            root.breath = 0.04 + 0.2 * Math.pow(0.5 + 0.5 * Math.sin(t * 2 * Math.PI / 5.5), 2);
        }
    }

    readonly property bool shown: ready && !(CompositorService.isNiri && NiriService.inOverview) && (audio.running || idleMode !== "off")

    Image {
        id: coreImage
        visible: false
        smooth: true
        asynchronous: true
        cache: false
        source: root.mask ? "file://" + root.mask.core : ""
    }
    Image {
        id: infoImage
        visible: false
        smooth: true
        asynchronous: true
        cache: false
        source: root.mask ? "file://" + root.mask.info : ""
    }
    Image {
        id: distImage
        visible: false
        smooth: true
        asynchronous: true
        cache: false
        source: root.mask ? "file://" + root.mask.dist : ""
    }
    Image {
        id: colorImage
        visible: false
        smooth: true
        asynchronous: true
        cache: false
        source: root.mask && root.mask.colors ? "file://" + root.mask.colors : ""
    }

    function b(i) {
        return audio.bands[i] || 0;
    }

    ShaderEffect {
        id: effect
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        visible: opacity > 0
        blending: true

        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }

        // property names must match the uniforms and samplers in shaders/glow.frag
        property var coreTex: coreImage
        property var infoTex: infoImage
        property var distTex: distImage
        property var colorTex: colorImage
        // every spot in its own color from the image, unless the accent is chosen
        property real spotColors: root.colorChoice === "accent" || !root.mask || !root.mask.colors ? 0 : 1

        property real fillMode: root.fillMode
        property real imgW: root.mask ? root.mask.width : 1
        property real imgH: root.mask ? root.mask.height : 1
        property real scrW: width
        property real scrH: height

        property real mode: ({
                "sync": 0,
                "bands": 1,
                "flow": 2,
                "sparkle": 3,
                "spectrum": 4
            })[root.mode] ?? 1
        property real time: 0
        property real level: audio.level
        property real idle: root.idle
        property real strength: root.strength
        property real bloom: root.bloomStrength
        property real speed: root.speed
        property color color: root.colorChoice === "accent" || !root.mask ? Theme.primary : root.mask.color

        property vector4d b0: Qt.vector4d(root.b(0), root.b(1), root.b(2), root.b(3))
        property vector4d b1: Qt.vector4d(root.b(4), root.b(5), root.b(6), root.b(7))
        property vector4d b2: Qt.vector4d(root.b(8), root.b(9), root.b(10), root.b(11))
        property vector4d b3: Qt.vector4d(root.b(12), root.b(13), root.b(14), root.b(15))
        property vector4d beatTime: Qt.vector4d(-100, -100, -100, -100)
        property vector4d beatStrength: Qt.vector4d(0, 0, 0, 0)

        fragmentShader: Qt.resolvedUrl("shaders/glow.frag.qsb")
    }
}
