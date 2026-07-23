import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../../core"
import "../../../services"

Rectangle {
    id: capsule
    height: 28
    implicitWidth: wsContainer.implicitWidth + 24
    radius: height / 2
    color: Theme.barPillBackgroundColor()
    border.width: Theme.barPillBorderWidth
    border.color: Theme.barPillBorderColor()

    property string outputName: ""
    property string primaryMonitorName: "HDMI-A-1"
    property var targetWorkspaces: outputName === primaryMonitorName
        ? [1, 2, 3, 4, 5]
        : [6, 7, 8, 9, 10]

    readonly property int pillHeight: 22
    readonly property int pillVPad: (height - pillHeight) / 2

    Item {
        id: wsContainer
        anchors.centerIn: parent
        implicitWidth: wsRow.implicitWidth
        implicitHeight: capsule.pillHeight

        Row {
            id: wsRow
            z: 1
            spacing: 6

            Repeater {
                model: capsule.targetWorkspaces

                Rectangle {
                    id: pill
                    property int wsId: modelData
                    property HyprlandWorkspace hyprWorkspace:
                        Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                    property bool isActive: hyprWorkspace?.active ?? false
                    property bool isUrgent: hyprWorkspace?.urgent ?? false

                    property bool isOccupied: iconsList.count > 0
                        || (hyprWorkspace?.toplevels.values.length ?? 0) > 0

                    readonly property int iconSlot: 16
                    readonly property int iconSpacing: 3
                    readonly property int iconPadding: 6
                    readonly property int emptyPillWidth: 14
                    readonly property int iconsRowWidth: {
                        const n = iconsList.count
                        if (n === 0)
                            return 0
                        return n * iconSlot + Math.max(0, n - 1) * iconSpacing + iconPadding * 2
                    }

                    ListModel { id: iconsList }

                    function syncIcons() {
                        const icons = HyprlandData.iconsForWorkspace(wsId)
                        var i = 0
                        while (i < icons.length && i < iconsList.count) {
                            if (iconsList.get(i).iconPath !== icons[i])
                                iconsList.set(i, { iconPath: icons[i] })
                            i++
                        }
                        while (iconsList.count > icons.length)
                            iconsList.remove(iconsList.count - 1, 1)
                        while (iconsList.count < icons.length)
                            iconsList.append({ iconPath: "" })
                        for (var j = 0; j < icons.length; j++) {
                            if (iconsList.get(j).iconPath !== icons[j])
                                iconsList.set(j, { iconPath: icons[j] })
                        }
                    }

                    Connections {
                        target: HyprlandData
                        function onWindowListChanged() {
                            pill.syncIcons()
                        }
                    }

                    height: capsule.pillHeight
                    radius: height / 2
                    clip: isOccupied
                    width: {
                        if (isOccupied)
                            return Math.max(iconSlot + iconPadding * 2, iconsRowWidth)
                        return emptyPillWidth
                    }

                    color: {
                        if (isActive)
                            return Theme.primary
                        if (isUrgent)
                            return Theme.err
                        if (isOccupied)
                            return Theme.alpha(Theme.primary, 0.25)
                        return Theme.surfaceVariant
                    }

                    border.width: isActive ? 0 : Theme.barPillBorderWidth
                    border.color: Theme.barPillBorderColor()
                    opacity: isUrgent && !isActive ? urgentPulse.value : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: 220
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Component.onCompleted: pill.syncIcons()

                    Row {
                        anchors.centerIn: parent
                        spacing: pill.iconSpacing
                        visible: pill.isOccupied

                        Repeater {
                            model: iconsList

                            Item {
                                required property var model
                                width: pill.iconSlot
                                height: pill.iconSlot
                                implicitWidth: pill.iconSlot
                                implicitHeight: pill.iconSlot

                                Image {
                                    anchors.centerIn: parent
                                    width: pill.iconSlot
                                    height: pill.iconSlot
                                    source: model.iconPath
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: pill.iconSlot * 2
                                    sourceSize.height: pill.iconSlot * 2
                                    mipmap: true
                                    smooth: true
                                    antialiasing: true
                                    opacity: pill.isActive ? 1 : 0.92
                                }
                            }
                        }
                    }

                    QtObject {
                        id: urgentPulse
                        property real value: 1.0
                    }

                    SequentialAnimation {
                        running: pill.isUrgent && !pill.isActive
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: urgentPulse
                            property: "value"
                            from: 1.0; to: 0.45
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: urgentPulse
                            property: "value"
                            from: 0.45; to: 1.0
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + capsule.outputName + '" })')
                            Hyprland.dispatch('hl.dsp.focus({ workspace = ' + pill.wsId + ' })')
                        }
                    }
                }
            }
        }

    }
}
