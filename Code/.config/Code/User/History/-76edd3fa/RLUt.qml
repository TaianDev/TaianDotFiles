import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: wsContainer
    spacing: 8
    
    property string outputName: "unknown"

    property var targetWorkspaces: outputName.indexOf("HDMI") !== -1 ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

    Repeater {
        model: targetWorkspaces

        Rectangle {
            id: pill
            property int wsId: modelData
            
            // 🛠️ BÚSQUEDA SEGURA: Recorremos la lista de Hyprland para buscar nuestra pastilla
            property var hyprWorkspace: {
                for (var i = 0; i < Hyprland.workspaces.length; ++i) {
                    if (Hyprland.workspaces[i].id === wsId) {
                        return Hyprland.workspaces[i];
                    }
                }
                return null;
            }
            
            // 🛡️ PROTECCIÓN UNDEFINED: Agregamos el '?' para que no falle al arrancar
            property bool isActive: Hyprland.activeWorkspace?.id === wsId
            property bool isOccupied: hyprWorkspace ? hyprWorkspace.windows > 0 : false

            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 200 } }

            width: isActive ? 32 : 12
            height: 12
            radius: 6 

            color: {
                if (isActive) return "#8cf0c3"       
                if (isOccupied) return "#ffffff"     
                return "#333333"                     
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                
                // 🎯 CORRECCIÓN DISPATCH: Se manda como un solo texto "workspace 1"
                onClicked: Hyprland.dispatch("workspace " + wsId)
            }
        }
    }
}