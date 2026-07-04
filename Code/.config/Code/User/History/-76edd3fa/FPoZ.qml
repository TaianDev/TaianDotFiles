import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: wsContainer
    spacing: 8
    
    // Recibe el nombre exacto de la salida de video desde Bar.qml
    property string outputName 
    
    // Asignación binaria: del 1-5 para HDMI, del 6-10 para la laptop
    property var targetWorkspaces: outputName === "HDMI-A-1" ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

    Repeater {
        model: targetWorkspaces

        Rectangle {
            id: pill
            property int wsId: modelData
            
            // Búsqueda moderna y eficiente del workspace en tiempo real
            property var hyprWorkspace: Array.from(Hyprland.workspaces).find(w => w.id === wsId)
            
            // Evaluación de estados (Segura contra arranques lentos con '?')
            property bool isActive: Hyprland.activeWorkspace?.id === wsId
            property bool isOccupied: hyprWorkspace ? hyprWorkspace.windows > 0 : false

            // Animaciones fluidas
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 200 } }

            // Dimensiones dinámicas
            width: isActive ? 32 : 12
            height: 12
            radius: 6 

            // Colores limpios
            color: isActive ? "#8cf0c3" : (isOccupied ? "#ffffff" : "#333333")

            // Interacción con Hyprland
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}