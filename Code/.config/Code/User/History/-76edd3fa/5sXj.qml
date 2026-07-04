import QtQuick
import Quickshell
import Quickshell.Hyprland

import QtQuick
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: workspaceCapsule
    
    // 🌟 CORRECCIÓN: La propiedad debe vivir en la raíz de la cápsula
    property string outputName

    height: 28 
    width: wsContainer.implicitWidth + 24 
    radius: height / 2 
    color: "#1a1a1a" 

    Row {
        id: wsContainer
        anchors.centerIn: parent 
        spacing: 8

        // Ahora lee la propiedad desde la raíz (workspaceCapsule)
        property var targetWorkspaces: workspaceCapsule.outputName === "HDMI-A-1" ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

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
                        // Ahora apunta correctamente a la propiedad de la cápsula
                        Hyprland.dispatch("focusmonitor " + workspaceCapsule.outputName)
                        Hyprland.dispatch("workspace " + wsId)
                    }
                }
            }
        }
    }
}