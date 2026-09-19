// AudioFX: player disc as a DMS desktop widget.
//
// Round cover with a visualizer (blob like in the dashboard, bar wreath or
// glow ring), spins during playback, track progress as a ring inside the
// cover edge, previous / play / next on hover.
//
// A real desktop widget rather than windows of its own: it appears in the DMS
// settings under Desktop Widgets, and position, size, grid and workspaces come
// from DMS. Staying in place across workspace switches (and staying clickable
// there) needs a separate patch to DMS that is not part of this plugin;
// without it the widget moves along like every DMS desktop widget, but works.
//
// Cover: MPRIS only delivers 120 x 120 px for Chromium-based players. If Pear
// Desktop runs with its API server enabled (plugin api-server,
// 127.0.0.1:26538), the widget fetches the original URL (`imageSrc`) and
// requests it at 1200 px.

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell.Services.Mpris
import qs.Common
import qs.Services
import qs.Widgets

Item {
    id: root

    // set by DesktopPluginWrapper
    property var pluginService: null
    property string pluginId: "audioFx"
    property string instanceId: ""
    property var instanceData: null
    property bool editMode: false
    property real widgetWidth: 360
    property real widgetHeight: 360

    readonly property real minWidth: 160
    readonly property real minHeight: 160
    readonly property bool forceSquare: true
    readonly property real defaultWidth: 360
    readonly property real defaultHeight: 360

    readonly property var _t: SettingsData.pluginSettings

    // The widget card in Settings > Desktop Widgets writes into this instance's
    // config, the plugin page into the plugin settings. The instance config is
    // read first, otherwise the card's choice of visualizer would have no effect.
    function cfg(key, fallback) {
        const c = root.instanceData?.config;
        if (c && c[key] !== undefined && c[key] !== null)
            return c[key];
        return SettingsData.getPluginSetting("audioFx", key, fallback);
    }

    readonly property string form: {
        root._t;
        return cfg("discForm", "blob");
    }
    // Only the visualizer around the cover; the cover stays opaque
    readonly property real vizOpacity: {
        root._t;
        return Math.max(10, Math.min(100, cfg("discOpacity", 100))) / 100;
    }
    readonly property int barCount: {
        root._t;
        return Math.max(24, Math.min(180, cfg("discBars", 72)));
    }
    readonly property real amplitude: {
        root._t;
        return Math.max(50, Math.min(400, cfg("discAmp", 200))) / 100;
    }
    readonly property int turnSeconds: {
        root._t;
        return Math.max(0, Math.min(300, cfg("discTurn", 90)));
    }
    // 0 keeps the original colors, 1 shows the cover in the accent color only
    readonly property real tint: {
        root._t;
        return Math.max(0, Math.min(100, cfg("discTint", 0))) / 100;
    }
    readonly property int ringWidth: {
        root._t;
        return Math.max(1, Math.min(16, cfg("discRing", 4)));
    }

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing

    // Make the cover as large as the widget allows while the visualizer still
    // fits. Blob: base radius 0.43, amplitude 0.115 x amp x 1.15 of the
    // DankAlbumArt span (= cover / 0.88). Bars: 5 px + 0.09 x cover x amp.
    readonly property real area: Math.min(width, height)
    // Ring: the halo reaches about 0.12 x cover x amp beyond the edge.
    readonly property real coverSize: form === "bars" ? Math.max(40, (area - 26) / (1 + 0.18 * amplitude)) : form === "glow" ? Math.max(40, (area / 2 - 6) / (0.5 + 0.12 * amplitude)) : Math.max(40, (area - 12) / (2 * (0.43 + 0.13225 * amplitude) / 0.88))
    readonly property real artSpan: coverSize / 0.88

    // ------------------------------------------------------------ high-res cover
    property string hiResArt: ""
    property string _hiResFor: ""
    readonly property string _title: player?.trackTitle ?? ""
    // The player's own cover. Chromium-based players (Pear) always write it to the
    // same temporary file, so the title goes into the URL: otherwise the image
    // cache keeps showing the cover of an earlier track.
    readonly property string _mprisArt: {
        const p = root.player;
        if (!p)
            return "";
        if (p.trackArtUrl)
            return p.trackArtUrl;
        const m = p.metadata;
        return m && m["mpris:artUrl"] ? m["mpris:artUrl"].toString() : "";
    }
    function fallbackArt(title) {
        if (!root._mprisArt)
            return "";
        return root._mprisArt + (root._mprisArt.indexOf("?") < 0 ? "?" : "&") + "t=" + encodeURIComponent(title);
    }

    on_TitleChanged: coverTimer.restart()
    Component.onCompleted: coverTimer.restart()

    // wait briefly: Pear reports the new title over MPRIS slightly before the API
    Timer {
        id: coverTimer
        interval: 700
        onTriggered: root.fetchCover(0)
    }

    function fetchCover(attempt) {
        const title = root._title;
        if (attempt === 0)
            retryTimer.round = 0;
        if (!title) {
            root.hiResArt = "";
            return;
        }
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let url = "";
            if (xhr.status === 200) {
                try {
                    const d = JSON.parse(xhr.responseText);
                    if (d && d.imageSrc && d.title === title)
                        url = String(d.imageSrc).replace(/=w\d+-h\d+/, "=w1200-h1200");
                } catch (e) {}
            }
            if (url) {
                root.hiResArt = url;
                root._hiResFor = title;
            } else if (attempt < 3 && xhr.status === 200) {
                // the API still lagged behind the title
                Qt.callLater(() => retryTimer.restart());
            } else if (root._hiResFor !== title) {
                // An empty URL would let DankAlbumArt fall back to the last cover it
                // loaded, which belongs to an earlier track.
                root.hiResArt = root.fallbackArt(title);
                root._hiResFor = title;
            }
        };
        xhr.open("GET", "http://127.0.0.1:26538/api/v1/song");
        xhr.send();
    }

    Timer {
        id: retryTimer
        interval: 1000
        property int round: 0
        onTriggered: root.fetchCover(++round)
    }

    // ------------------------------------------------------------ progress
    readonly property real trackLength: MprisController.activePlayerStableLength
    readonly property real progressTarget: (player && trackLength > 0) ? Math.max(0, Math.min(1, (player.position || 0) / trackLength)) : 0
    property real progress: 0

    onProgressTargetChanged: {
        if (Math.abs(progressTarget - progress) > 0.05 || !playing) {
            progressAnim.stop();
            progress = progressTarget;
        } else {
            progressAnim.to = progressTarget;
            progressAnim.restart();
        }
    }

    NumberAnimation {
        id: progressAnim
        target: root
        property: "progress"
        duration: 1000
    }

    // ------------------------------------------------------------ buttons
    readonly property real bigButton: coverSize * 0.26
    readonly property real smallButton: coverSize * 0.17
    readonly property real sideOffset: bigButton / 2 + coverSize * 0.07 + smallButton / 2
    property string hoverPart: ""

    function partAt(x, y) {
        const cx = width / 2;
        const dy = y - height / 2;
        const near = (mx, r) => Math.hypot(x - mx, dy) <= r;
        if (near(cx, bigButton / 2))
            return "play";
        if (near(cx - sideOffset, smallButton / 2 + 4))
            return "prev";
        if (near(cx + sideOffset, smallButton / 2 + 4))
            return "next";
        return "";
    }

    function trigger(part) {
        if (!player)
            return;
        if (part === "play" && player.canTogglePlaying)
            player.togglePlaying();
        else if (part === "prev")
            MprisController.previousOrRewind();
        else if (part === "next")
            MprisController.next();
    }

    // ------------------------------------------------------------ drawing
    Item {
        id: spinner
        anchors.fill: parent

        NumberAnimation on rotation {
            from: 0
            to: 360
            duration: Math.max(1, root.turnSeconds) * 1000
            loops: Animation.Infinite
            running: root.turnSeconds > 0 && root.visible
            paused: running && !root.playing
        }

        AudioFxHalo {
            width: root.artSpan
            height: root.artSpan
            anchors.centerIn: parent
            visible: root.form === "blob"
            playing: root.playing && root.form === "blob"
            opacity: root.vizOpacity
            amplitudeScale: root.amplitude
        }

        DankAlbumArt {
            width: root.artSpan
            height: root.artSpan
            anchors.centerIn: parent
            activePlayer: root.player
            artUrl: root.hiResArt
            albumSize: root.coverSize
            showAnimation: false

            layer.enabled: root.tint > 0
            layer.effect: MultiEffect {
                colorization: root.tint
                colorizationColor: Theme.primary
            }
        }
    }

    AudioFxDiscBars {
        anchors.fill: parent
        z: -1
        active: root.visible && root.form === "bars"
        strength: root.vizOpacity
        playing: root.playing
        coverSize: root.coverSize
        amplitude: root.amplitude
        barCount: root.barCount
        windowKey: "widget-" + (root.instanceId || "global")
    }

    AudioFxRing {
        anchors.fill: parent
        z: -1
        active: root.visible && root.form === "glow"
        opacity: root.vizOpacity
        playing: root.playing
        coverSize: root.coverSize
        amplitude: root.amplitude
        windowKey: "widget-" + (root.instanceId || "global")
    }

    Shape {
        id: ring
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        readonly property real radius: root.coverSize / 2 - root.ringWidth / 2 - 3

        ShapePath {
            strokeColor: Qt.rgba(0, 0, 0, 0.4)
            strokeWidth: root.ringWidth
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap

            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: root.progress > 0 ? Theme.primary : "transparent"
            strokeWidth: root.ringWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                sweepAngle: 360 * root.progress
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: mouseArea.containsMouse && root.player && !root.editMode ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            width: root.coverSize
            height: root.coverSize
            radius: width / 2
            anchors.centerIn: parent
            color: Qt.rgba(0, 0, 0, 0.45)
        }

        component DiscButton: Rectangle {
            id: button
            required property string part
            required property string icon
            required property real size
            required property real offset
            property bool emphasized: false

            readonly property bool hovered: root.hoverPart === part

            width: size
            height: size
            radius: size / 2
            x: root.width / 2 + offset - size / 2
            y: root.height / 2 - size / 2
            color: emphasized ? (hovered ? Qt.lighter(Theme.primary, 1.15) : Theme.primary) : (hovered ? Qt.rgba(1, 1, 1, 0.18) : "transparent")
            scale: hovered ? 1.08 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                }
            }

            DankIcon {
                anchors.centerIn: parent
                name: button.icon
                size: button.size * 0.55
                color: button.emphasized ? Theme.primaryText : "white"
                weight: 500
            }
        }

        DiscButton {
            part: "prev"
            icon: "skip_previous"
            size: root.smallButton
            offset: -root.sideOffset
        }
        DiscButton {
            part: "play"
            icon: root.playing ? "pause" : "play_arrow"
            size: root.bigButton
            offset: 0
            emphasized: true
        }
        DiscButton {
            part: "next"
            icon: "skip_next"
            size: root.smallButton
            offset: root.sideOffset
        }
    }

    // left button only: the right button belongs to DMS for dragging and resizing
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.hoverPart !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPositionChanged: mouse => root.hoverPart = root.partAt(mouse.x, mouse.y)
        onExited: root.hoverPart = ""
        onClicked: mouse => root.trigger(root.partAt(mouse.x, mouse.y))
    }
}
