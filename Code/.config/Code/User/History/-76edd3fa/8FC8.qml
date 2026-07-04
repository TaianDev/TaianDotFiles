import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: wsContainer
    spacing: 8
    
    property string outputName: "unknown"
    
    // ✨ SIMPLIFICACIÓN 1: Una sola línea de lógica binaria
    property var targetWorkspaces: outputName === "HDMI-A-1" ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

    Repeater {
        model: targetWorkspaces

        Rectangle {
            id: pill
            property int wsId: modelData
            
            // ✨ SIMPLIFICACIÓN 2: Búsqueda moderna en un array
            property var hyprWorkspace: Array.from(Hyprland.workspaces).find(w => w.id === wsId)
            
            property bool isActive: Hyprland.activeWorkspace?.id === wsId
            property bool isOccupied: hyprWorkspace ? hyprWorkspace.windows > 0 : false

            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 200 } }

            width: isActive ? 32 : 12
            height: 12
            radius: 6 

            // ✨ SIMPLIFICACIÓN 3: Evaluación de color en cadena
            color: isActive ? "#8cf0c3" : (isOccupied ? "#ffffff" : "#333333")

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}