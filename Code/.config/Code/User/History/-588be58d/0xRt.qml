import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../components"
import "../components/network"
import "../components/network/popup"
import "../components/date"
import "components/theme"

PanelWindow {
    id: flareBar
    property int barHeight: 40
    property int flareRadius: 20
    property color themeColor: "#000000"

    anchors { top: true; left: true; right: true }
    implicitHeight: barHeight + flareRadius
    exclusiveZone: barHeight
    WlrLayershell.namespace: "flare_bar_" + screen.name
    color: "transparent"

    Rectangle {
        id: mainBody
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: flareBar.barHeight
        color: flareBar.themeColor

        // 1. Tu Lanzador de Aplicaciones Actual
        Rectangle {
            id: launcherBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            width: 28
            height: 28
            radius: 8
            
            color: launcherMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text { anchors.centerIn: parent; text: "🚀"; font.pixelSize: 14 }

            MouseArea {
                id: launcherMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appLauncher.isOpened = !appLauncher.isOpened
            }
        }

        // 🌟 2. NUEVO: Botón del Theme Changer
        Rectangle {
            id: themeBtn
            anchors.left: launcherBtn.right // Se ancla directo al botón de apps
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8 // Pequeño espacio de separación
            width: 28
            height: 28
            radius: 8
            
            color: themeMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }

            Text { anchors.centerIn: parent; text: "🎨"; font.pixelSize: 14 }

            MouseArea {
                id: themeMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: themeChanger.isOpened = !themeChanger.isOpened
            }
        }
        WorkspacePills {
            id: workspacePills       
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            outputName: flareBar.screen.name
        }

    
        MusicWidget {
            id: music
            anchors.left: workspacePills.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 20
        }
        
        SystemPill {
            anchors.centerIn: parent
        }
        
        DateWidget {
            id: dateWidget
            anchors.right: networkPill.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 12 
        }

        NetworkPill {
            id: networkPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 20
        }
    }

    MusicPopup {
        widgetRef: music
        parentWindow: flareBar
    }

    Shape {
        anchors.top: mainBody.bottom
        anchors.left: parent.left
        width: flareBar.flareRadius
        height: flareBar.flareRadius
        antialiasing: true
        layer.enabled: true
        layer.samples: 8
        ShapePath {
            fillColor: flareBar.themeColor
            strokeWidth: 0
            startX: 0; startY: 0
            PathLine { x: flareBar.flareRadius; y: 0 }
            PathQuad { x: 0; y: flareBar.flareRadius; controlX: 0; controlY: 0 }
        }
    }

    Shape {
        anchors.top: mainBody.bottom
        anchors.right: parent.right
        width: flareBar.flareRadius
        height: flareBar.flareRadius
        antialiasing: true
        layer.enabled: true
        layer.samples: 8
        ShapePath {
            fillColor: flareBar.themeColor
            strokeWidth: 0
            startX: 0; startY: 0
            PathQuad {
                x: flareBar.flareRadius
                y: flareBar.flareRadius
                controlX: flareBar.flareRadius
                controlY: 0
            }
            PathLine { x: flareBar.flareRadius; y: 0 }
            PathLine { x: 0; y: 0 }
        }
    }
}