import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../components"

PanelWindow {
    id: flareBar
    property int barHeight: 40
    property int flareRadius: 20
    property color themeColor: "#000000"

    anchors {
        top: true
        left: true
        right: true
    }

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

        WorkspacePills {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20
            outputName: flareBar.screen.name  // <-- screen.name en lugar de modelData.name
        }

        Text {
            anchors.centerIn: parent
            text: "UnU"
            color: "#ffffff"
            font.bold: true
        }
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