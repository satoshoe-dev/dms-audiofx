// AudioFX: round album cover for the player disc.
//
// Own copy of the logic from DMS 1.6 `Widgets/DankAlbumArt.qml`, which
// DMS 2.0 removed without a replacement. Without the blob halo and the
// animated Apple Music cover (the disc draws its own visualizer). The round
// crop uses Quickshell's ClippingRectangle instead of DankCircularImage, so
// the file loads the same way under DMS 1.6 and 2.0.

import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.Common
import qs.Widgets

Item {
    id: root

    property MprisPlayer activePlayer
    property string artUrl: ""
    property color accentColor: Theme.primary
    property real albumSize: Math.min(width, height) * 0.88

    property string lastValidArtUrl: ""
    // Live MPRIS url, always valid for the current track; fallback so the cover is never blank.
    readonly property string rawArtUrl: {
        const p = activePlayer;
        if (!p)
            return "";
        if (p.trackArtUrl)
            return p.trackArtUrl;
        const m = p.metadata;
        return m && m["mpris:artUrl"] ? m["mpris:artUrl"].toString() : "";
    }
    readonly property string curArt: artUrl || lastValidArtUrl || rawArtUrl
    property string _prevArt: ""
    property bool _fadePending: false
    property string _srcOverride: "" // forces the live url when the resolved one fails
    readonly property string _mainSrc: _srcOverride !== "" ? _srcOverride : curArt

    onActivePlayerChanged: lastValidArtUrl = ""

    onCurArtChanged: {
        _srcOverride = "";
        // The outgoing cover stays on top until the new one has decoded, then fades out.
        if (_prevArt !== "" && _prevArt !== curArt) {
            fadeImage.source = _prevArt;
            fadeArt.opacity = 1;
            _fadePending = true;
            fadeSafety.restart();
            Qt.callLater(_maybeStartFade); // cached images load synchronously
        }
        _prevArt = curArt;
    }

    function _maybeStartFade() {
        if (!_fadePending)
            return;
        if (mainImage.status !== Image.Ready && mainImage.status !== Image.Error)
            return;
        _fadePending = false;
        fadeSafety.stop();
        fadeOut.restart();
    }

    Timer {
        id: fadeSafety
        interval: 1200
        onTriggered: {
            if (root._fadePending) {
                root._fadePending = false;
                fadeOut.restart();
            }
        }
    }

    NumberAnimation {
        id: fadeOut
        target: fadeArt
        property: "opacity"
        from: 1
        to: 0
        duration: 300
        easing.type: Easing.InOutQuad
    }

    Rectangle {
        id: mainArt
        width: root.albumSize
        height: root.albumSize
        anchors.centerIn: parent
        radius: width / 2
        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
        border.color: root.accentColor
        border.width: 2

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Math.min(width, height) / 2
            color: "transparent"

            Image {
                id: mainImage
                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                sourceSize.width: Math.max(width * 2, 128)
                sourceSize.height: Math.max(height * 2, 128)
                source: root._mainSrc
                visible: status === Image.Ready && root._mainSrc !== ""

                onStatusChanged: {
                    if (status === Image.Ready && root._mainSrc !== "")
                        root.lastValidArtUrl = root._mainSrc;
                    else if (status === Image.Error && root._srcOverride === "" && root.rawArtUrl !== "" && root.rawArtUrl !== root._mainSrc)
                        root._srcOverride = root.rawArtUrl; // resolved url dead, use the live MPRIS url
                    root._maybeStartFade();
                }
            }
        }

        DankIcon {
            anchors.centerIn: parent
            visible: !mainImage.visible
            name: "album"
            size: Math.round(parent.width * 0.5)
            color: Theme.surfaceVariantText
        }
    }

    // Outgoing cover, only visible while it fades out over the new one.
    Rectangle {
        id: fadeArt
        width: root.albumSize
        height: root.albumSize
        anchors.centerIn: parent
        radius: width / 2
        color: "transparent"
        border.color: root.accentColor
        border.width: 2
        opacity: 0
        visible: opacity > 0

        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Math.min(width, height) / 2
            color: "transparent"

            Image {
                id: fadeImage
                anchors.fill: parent
                asynchronous: true
                fillMode: Image.PreserveAspectCrop
                smooth: true
                mipmap: true
                sourceSize.width: Math.max(width * 2, 128)
                sourceSize.height: Math.max(height * 2, 128)
            }
        }
    }
}
