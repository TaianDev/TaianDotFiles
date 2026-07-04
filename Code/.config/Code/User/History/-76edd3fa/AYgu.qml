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
            property var hyprWorkspace: Array.from(Hyprland.workspaces).find(w => w.id === wsId)

            // Usamos Hyprland.activeWorkspace como fuente reactiva global
            // y además consultamos el monitor para saber cuál está activo en él
            property bool isActive: {
                // Este binding se re-evalúa cada vez que cambia activeWorkspace
                let _ = Hyprland.activeWorkspace?.id
                let monitor = Array.from(Hyprland.monitors).find(m => m.name === wsContainer.outputName)
                return monitor?.activeWorkspace?.id === wsId
            }

            property bool isOccupied: hyprWorkspace ? hyprWorkspace.windows > 0 : false

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