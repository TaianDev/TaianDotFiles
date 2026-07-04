import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root
    width: 154 
    height: 72
    radius: 16
    color: Qt.rgba(0.2, 0.2, 0.2, 0.8) 

    property string title: ""
    property string subtitle: ""
    property string iconSource: ""
    property color  iconTint: "#ffffff"
    property bool   isToggled: false
    
    signal toggleClicked()
    signal arrowClicked()

    // ── Icono ──
    Item {
        x: 12; y: 12
        width: 16; height: 16
        Image {
            id: icn
            anchors.fill: parent
            source: root.iconSource
            sourceSize: Qt.size(16, 16)
            visible: false
        }
        ColorOverlay {
            anchors.fill: icn
            source: icn
            color: root.iconTint
        }
    }

    // ── Interruptor ──
    Rectangle {
        x: root.width - width - 12
        y: 10
        width: 36; height: 20
        radius: 10
        color: root.isToggled ? "#34c759" : Qt.rgba(1, 1, 1, 0.2) 
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            width: 16; height: 16; radius: 8
            color: "#ffffff"
            y: 2
            x: root.isToggled ? 18 : 2
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleClicked()
        }
    }

    // ── Textos ──
    Column {
        x: 12
        y: 34
        spacing: 2
        Text { text: root.title; color: "#ffffff"; font.pixelSize: 13; font.bold: true }
        Text { 
            text: root.subtitle; color: Qt.rgba(1, 1, 1, 0.6); 
            font.pixelSize: 11; width: 100; elide: Text.ElideRight 
        }
    }

    // ── Flecha ──
    Text {
        x: root.width - width - 12
        y: 44
        text: "›"
        color: Qt.rgba(1, 1, 1, 0.5)
        font.pixelSize: 18
        font.bold: true

        MouseArea {
            anchors.fill: parent
            anchors.margins: -10 
            cursorShape: Qt.PointingHandCursor
            onClicked: root.arrowClicked()
        }
    }
}