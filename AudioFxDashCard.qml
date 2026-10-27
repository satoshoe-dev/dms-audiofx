// AudioFX: overview card in the dashboard, DMS 2.0 and newer
// (`components.dashCard` in plugin.json).
//
// DMS 1.6 does not know the "dashCard" surface. It skips it with one log line
// and loads the other surfaces as before, so this file is never compiled
// there and may use `DashCardComponent`, which only exists since 2.0.
//
// The card holds the same quick controls as the row in the media tab
// (`AudioFxDashRow.qml`): on/off and switching between wave and bars.
// Add it in the dash: overview, pencil, Add widget.

import QtQuick
import qs.Common
import qs.Modules.Plugins

DashCardComponent {
    id: root

    // No tab of its own, so a click on the card goes nowhere.
    opensTab: false

    StyledText {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        text: "AudioFX"
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Theme.fontWeightMedium
        color: root.mutedColor
        elide: Text.ElideRight
    }

    AudioFxDashRow {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        // The card draws the surface already.
        color: "transparent"
        // In edit mode the card is moved, not switched.
        enabled: root.interactive
    }
}
