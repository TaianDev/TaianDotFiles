import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    width: 154 // Tamaño exacto de media columna
    height: 44
    radius: 12
    color: Qt.rgba(0.2, 0.2, 0.2, 0.8)

    property string iconText: ""
    property string title: ""
    property bool   isToggled: false
    property color  activeColor: "#0a84ff"

    signal clicked()

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10
        
        Text { text: root.iconText; color: root.isToggled ? root.activeColor : "#ffffff"; font.pixelSize: 16 }
        Text { text: root.title; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
        
        Rectangle {
            width: 36; height: 20; radius: 10
            color: root.isToggled ? root.activeColor : Qt.rgba(1, 1, 1, 0.2)
            Rectangle {
                width: 16; height: 16; radius: 8
                color: "#ffffff"
                y: 2; x: root.isToggled ? 18 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}