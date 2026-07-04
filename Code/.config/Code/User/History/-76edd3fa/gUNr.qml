import QtQuick
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: capsule
    color: Qt.rgba(1, 1, 1, 0.08)
    radius: 12
    border.width: 0.5
    border.color: Qt.rgba(1, 1, 1, 0.12)
    implicitWidth: wsRow.implicitWidth + 16
    implicitHeight: wsRow.implicitHeight + 12

    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 8

        property string outputName: capsule.outputName
        property var targetWorkspaces: capsule.targetWorkspaces

        Repeater {
            model: targetWorkspaces

            Rectangle {
                id: pill
                property int wsId: modelData
                property HyprlandWorkspace hyprWorkspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                property bool isActive: hyprWorkspace?.active ?? false
                property bool isOccupied: (hyprWorkspace?.toplevels.values.length ?? 0) > 0

                Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                Behavior on color { ColorAnimation { duration: 200 } }

                width: isActive ? 32 : 12
                height: 12
                radius: 6
                color: isActive ? "#8cf0c3" : (isOccupied ? "#ffffff" : "#333333")

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("focusmonitor " + capsule.outputName)
                        Hyprland.dispatch("workspace " + wsId)
                    }
                }
            }
        }
    }

    property string outputName
    property var targetWorkspaces: outputName === "HDMI-A-1" ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]
}