import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../core"
import "../components"
import "../components/network"
import "../components/network/popup"
import "../components/date"

PanelWindow {
    id: flareBar
    property int barHeight: 40
    property int flareRadius: 20

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
        color: Theme.background
        Behavior on color { ColorAnimation { duration: 300 } }

        Row {
            id: leftGroup
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            WorkspacePills {
                id: workspacePills
                outputName: flareBar.screen.name
            }

            MusicWidget {
                id: music
            }
        }

        DateWidget {
            id: dateWidget
            anchors.centerIn: parent
        }

        Row {
            id: rightGroup
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            ScreenshotPill { }

            SystemPill { }

            NetworkPill {
                id: networkPill
                hostWindow: flareBar
            }
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
            fillColor: Theme.background
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
            fillColor: Theme.background
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
