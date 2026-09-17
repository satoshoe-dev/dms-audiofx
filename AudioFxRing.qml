// AudioFX: glow ring around the cover of the player disc.
//
// Third style next to the blob and the bar wreath, matching the glow in the
// wallpaper: a soft ring of light just outside the cover that breathes with
// the level, carries the spectrum around its circumference and flares up on
// bass beats. Draws additively (shaders/ring.frag), audio from AudioFxLevels.

pragma ComponentBehavior: Bound

import QtQuick
import qs.Common

Item {
    id: root

    property bool active: false
    property bool playing: false
    property real coverSize: 260
    property real amplitude: 2.0
    property string windowKey: "global"
    property color color: Theme.primary

    readonly property real half: Math.max(1, Math.min(width, height) / 2)

    AudioFxLevels {
        id: audio
        active: root.active && root.playing
        fps: 30
        key: "ring-" + root.windowKey
        onFrame: effect.time = (Date.now() % 3600000) / 1000
    }

    ShaderEffect {
        id: effect
        width: root.half * 2
        height: root.half * 2
        anchors.centerIn: parent
        opacity: root.active ? 1 : 0
        visible: opacity > 0
        blending: true

        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }

        // property names must match the uniforms in shaders/ring.frag
        property real radius: (root.coverSize / 2 + 3) / root.half
        property real thickness: Math.max(3, root.coverSize * 0.016 * root.amplitude) / root.half
        property real level: audio.level
        // without playback the ring keeps glowing quietly
        property real idle: audio.running ? 0.08 : 0.22
        property real time: 0
        property real strength: 1.0
        property color color: root.color

        function b(i) {
            return audio.bands[i] || 0;
        }
        property vector4d b0: Qt.vector4d(b(0), b(1), b(2), b(3))
        property vector4d b1: Qt.vector4d(b(4), b(5), b(6), b(7))
        property vector4d b2: Qt.vector4d(b(8), b(9), b(10), b(11))
        property vector4d b3: Qt.vector4d(b(12), b(13), b(14), b(15))

        fragmentShader: Qt.resolvedUrl("shaders/ring.frag.qsb")
    }
}
