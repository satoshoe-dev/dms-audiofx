// AudioFX: control center tile, switches the desktop visualizer on and off.
//
// The switch lives in the plugin settings (not in the widget instance),
// because the tile knows no instance. The desktop part reads the same value.

import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    // pluginSettings is reassigned as a whole on every write; the dependency
    // makes the binding reactive.
    readonly property var _settingsTrigger: SettingsData.pluginSettings
    readonly property bool switchedOn: {
        root._settingsTrigger;
        return SettingsData.getPluginSetting("audioFx", "on", true);
    }

    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false

    ccWidgetIcon: switchedOn ? "graphic_eq" : "equalizer"
    ccWidgetPrimaryText: I18n.trFor("audioFx", "Visualizer")
    ccWidgetSecondaryText: !switchedOn ? I18n.trFor("audioFx", "Off") : (playing ? I18n.trFor("audioFx", "Running") : I18n.trFor("audioFx", "Ready"))
    ccWidgetIsActive: switchedOn

    onCcWidgetToggled: SettingsData.setPluginSetting("audioFx", "on", !root.switchedOn)

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.switchedOn ? "graphic_eq" : "equalizer"
                size: Theme.iconSize - 4
                color: root.switchedOn ? Theme.primary : Theme.surfaceVariantText
            }
        }
    }

    pillClickAction: () => SettingsData.setPluginSetting("audioFx", "on", !root.switchedOn)
}
