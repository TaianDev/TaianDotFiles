import QtQuick
import QtQuick.Layouts

Item {
    id: root
    
    // Propiedades inyectadas
    property color textMain: "#ffffff"
    property color bgLighter: "#2d2d2d"

    property int elapsedMs: 0
    property bool running: false

    Timer {
        interval: 50
        running: root.running
        repeat: true
        onTriggered: root.elapsedMs += 50
    }

    function formatSW(ms) {
        let h = Math.floor(ms / 3600000).toString().padStart(2, '0')
        let m = Math.floor((ms % 3600000) / 60000).toString().padStart(2, '0')
        let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
        let d = Math.floor((ms % 1000) / 100)
        return h + ":" + m + ":" + s + "." + d
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.formatSW(root.elapsedMs)
            color: root.textMain
            font.pixelSize: 48
            font.weight: Font.Thin
            style: Text.Outline
            styleColor: Qt.rgba(1, 1, 1, 0.2)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            Rectangle {
                width: 48; height: 48; radius: 24
                color: root.bgLighter
                Text { anchors.centerIn: parent; text: root.running ? "⏸" : "▶"; color: root.textMain; font.pixelSize: 20 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.running = !root.running }
            }

            Rectangle {
                width: 48; height: 48; radius: 24
                color: root.bgLighter
                Text { anchors.centerIn: parent; text: "⏹"; color: root.textMain; font.pixelSize: 20 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.running = false; root.elapsedMs = 0 }
                }
            }
        }
    }
}