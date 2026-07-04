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

            // Obtenemos el objeto HyprlandWorkspace directamente
            property HyprlandWorkspace hyprWorkspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null

            // .active ya es una propiedad reactiva nativa del objeto
            property bool isActive: hyprWorkspace?.active ?? false

            // .toplevels es un ObjectModel, usamos su count
            property bool isOccupied: hyprWorkspace ? hyprWorkspace.toplevels.count > 0 : false

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