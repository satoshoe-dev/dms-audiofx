// AudioFX: quick controls in the media tab of the dashboard.
//
// DMS has no plugin interface for dashboard content (plugins can serve the
// bar, control center, desktop and launcher, nothing else). This file is
// therefore meant to be hooked in by an external patch that adds a Loader
// with `source: "AudioFxDashRow.qml"` to the media tab. The content lives
// here on purpose rather than in the patch: if the anchor breaks after a DMS
// update, only one line is lost, not the controls.
//
// Deliberately small: on/off and switching between wave and bars. Everything
// else is in Settings > Plugins > AudioFX.
//
// The two buttons are plain rectangles with their own MouseArea, written out
// one by one. Inside a Repeater with a model or an inline component
// (`component FormButton: Rectangle`) they receive no clicks at this spot.

import QtQuick
import qs.Common
import qs.Widgets

Rectangle {
    id: row

    // pluginSettings is reassigned as a whole on every write; the dependency
    // makes the bindings reactive.
    readonly property var _t: SettingsData.pluginSettings

    function cfg(key, fallback) {
        return SettingsData.getPluginSetting("audioFx", key, fallback);
    }

    readonly property bool switchedOn: {
        row._t;
        return cfg("on", true);
    }
    readonly property string form: {
        row._t;
        return cfg("form", "waveFilled");
    }
    function isWaveForm(f) {
        return ["wave", "waveFilled", "waveMirrored"].indexOf(f) >= 0;
    }

    readonly property bool isWave: isWaveForm(form)

    // Remember the last used form of each kind, so switching doesn't fall back
    // to the default every time.
    property string lastWave: "waveFilled"
    property string lastBars: "bars"

    // Do NOT check `isWave` here: it is a separate binding on `form`, and on
    // creation this handler runs before it is re-evaluated. It still reads
    // `false` then, a wave form gets remembered as "last bars", and afterwards
    // both buttons set the same value.
    onFormChanged: {
        if (isWaveForm(form))
            lastWave = form;
        else
            lastBars = form;
    }

    function setForm(target) {
        SettingsData.setPluginSetting("audioFx", "form", target);
        if (!row.switchedOn)
            SettingsData.setPluginSetting("audioFx", "on", true);
    }

    implicitWidth: content.implicitWidth + Theme.spacingM * 2
    implicitHeight: content.implicitHeight + Theme.spacingS * 2
    radius: Theme.cornerRadius
    color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.72)

    Row {
        id: content

        anchors.centerIn: parent
        spacing: Theme.spacingS

        DankToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: row.switchedOn
            hideText: true
            onToggled: value => SettingsData.setPluginSetting("audioFx", "on", value)
        }

        Rectangle {
            id: waveButton

            anchors.verticalCenter: parent.verticalCenter
            width: waveContent.implicitWidth + Theme.spacingM
            height: 28
            radius: Theme.cornerRadius
            opacity: row.switchedOn ? 1 : 0.5
            color: row.isWave ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22) : (waveMouse.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.1) : "transparent")

            Row {
                id: waveContent

                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "show_chart"
                    size: Theme.iconSize - 6
                    color: row.isWave ? Theme.primary : Theme.surfaceVariantText
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.trFor("audioFx", "Wave")
                    font.pixelSize: Theme.fontSizeSmall
                    color: row.isWave ? Theme.primary : Theme.surfaceVariantText
                }
            }

            MouseArea {
                id: waveMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    row.setForm(row.lastWave);
                }
            }
        }

        Rectangle {
            id: barsButton

            anchors.verticalCenter: parent.verticalCenter
            width: barsContent.implicitWidth + Theme.spacingM
            height: 28
            radius: Theme.cornerRadius
            opacity: row.switchedOn ? 1 : 0.5
            color: !row.isWave ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22) : (barsMouse.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.1) : "transparent")

            Row {
                id: barsContent

                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "bar_chart"
                    size: Theme.iconSize - 6
                    color: !row.isWave ? Theme.primary : Theme.surfaceVariantText
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.trFor("audioFx", "Bars")
                    font.pixelSize: Theme.fontSizeSmall
                    color: !row.isWave ? Theme.primary : Theme.surfaceVariantText
                }
            }

            MouseArea {
                id: barsMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    row.setForm(row.lastBars);
                }
            }
        }
    }
}
