import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: wsContainer
    spacing: 8

    property string outputName
    property var targetWorkspaces: outputName === "HDMI-A-1" ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

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
                    Hyprland.dispatch("focusmonitor " + wsContainer.outputName)
                    Hyprland.dispatch("workspace " + wsId)
                }
            }
        }
    }
}