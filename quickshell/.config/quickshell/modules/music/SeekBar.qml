import QtQuick
import "../../utils"

Column {
    id: root
    spacing: 4

    property var player: null
    property bool playing: false
    property real progress: 0
    property real positionSecs: 0
    property real lengthSecs: 0

    width: parent ? parent.width : 260

    Item {
        width: parent.width; height: 14

        Rectangle {
            id: track
            width: parent.width; height: 4; radius: 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(1, 1, 1, 0.18)

            Rectangle {
                id: fill
                width: track.width * root.progress
                height: parent.height; radius: 2; color: "#ffffff"
            }

            Rectangle {
                width: 10; height: 10; radius: 5; color: "#ffffff"
                anchors.verticalCenter: parent.verticalCenter
                x: Math.max(0, fill.width - 5)
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (!root.player?.canSeek) return
                root.player.position = (mouse.x / width) * root.player.length
            }
        }
    }

    Item {
        width: parent.width; height: 14

        Text {
            anchors.left: parent.left
            text: TimeUtils.formatMMSS(root.positionSecs)
            color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10
        }

        Text {
            anchors.right: parent.right
            text: TimeUtils.formatMMSS(root.lengthSecs)
            color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 10
        }
    }
}
