import QtQuick
import Quickshell
import "../../core"
import "../../utils"

Row {
    id: root
    spacing: 10

    property var playerList: []
    property int activeIndex: 0
    property string iconsPath: ""

    readonly property bool hasPlayers: playerList.length > 1
    visible: hasPlayers
    height: hasPlayers ? 36 : 0

    signal playerChanged(int index)

    function playerIcon(mprisPlayer) {
        if (!mprisPlayer)
            return ""
        const candidates = IconResolver.playerIconCandidates(mprisPlayer)
        return IconResolver.resolveIconFromCandidates(candidates)
    }

    Repeater {
        id: repeater
        model: root.playerList

        Rectangle {
            width: 36; height: 36; radius: 10
            color: index === root.activeIndex
                ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.06)
            border.width: index === root.activeIndex ? 1 : 0
            border.color: Qt.rgba(1, 1, 1, 0.35)
            Behavior on color { ColorAnimation { duration: 150 } }

            property string iconSrc: root.playerIcon(modelData)

            Image {
                anchors { fill: parent; margins: 6 }
                source: parent.iconSrc
                sourceSize: Qt.size(24, 24)
                fillMode: Image.PreserveAspectFit
                cache: true
                asynchronous: true
                visible: parent.iconSrc !== "" && status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: (modelData.identity ?? "?")[0].toUpperCase()
                color: "#ffffff"
                font.pixelSize: 14; font.weight: Font.Medium
                visible: parent.iconSrc === "" || parent.children[1].status === Image.Error
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.playerChanged(index)
            }
        }
    }
}
