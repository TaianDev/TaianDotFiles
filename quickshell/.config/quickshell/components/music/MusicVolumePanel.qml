import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property var    player: null
    property string artUrl:   ""
    property int    radius:   12

    readonly property bool supported: root.player?.volumeSupported ?? false
    readonly property real volumePct: Math.round((root.player?.volume ?? 0) * 100)

    implicitWidth: 52
    implicitHeight: 148

    Item {
        id: panel
        anchors.fill: parent
        clip: true

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: panel.width
                height: panel.height
                radius: root.radius
            }
        }

        Item {
            anchors.fill: parent
            visible: root.artUrl !== ""

            Image {
                id: artBg
                anchors.centerIn: parent
                source: root.artUrl
                width: parent.width + 40
                height: parent.height + 40
                fillMode: Image.PreserveAspectCrop
                cache: true
                asynchronous: true
                sourceSize: Qt.size(120, 120)
            }

            FastBlur {
                anchors.fill: artBg
                source: artBg
                radius: 48
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.68)
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.artUrl === ""
            color: Qt.rgba(0, 0, 0, 0.82)
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 0.5
            border.color: Qt.rgba(1, 1, 1, 0.12)
        }

        Column {
            anchors.centerIn: parent
            spacing: 10

            Slider {
                id: volSlider
                width: 28
                height: 104
                orientation: Qt.Vertical
                from: 0
                to: 100
                value: root.volumePct
                enabled: root.player !== null

                background: Rectangle {
                    x: volSlider.leftPadding + volSlider.availableWidth / 2 - width / 2
                    y: volSlider.topPadding
                    width: 4
                    height: volSlider.availableHeight
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.18)

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: volSlider.visualPosition * parent.height
                        radius: 2
                        color: "#ffffff"
                    }
                }

                handle: Rectangle {
                    x: volSlider.leftPadding + volSlider.availableWidth / 2 - width / 2
                    y: volSlider.topPadding + volSlider.visualPosition * (volSlider.availableHeight - height)
                    width: 10
                    height: 10
                    radius: 5
                    color: "#ffffff"
                }

                onMoved: {
                    if (root.player)
                        root.player.volume = value / 100
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.volumePct + "%"
                color: Qt.rgba(1, 1, 1, 0.65)
                font.pixelSize: 10
                font.family: "monospace"
            }
        }
    }

    Connections {
        target: root.player
        function onVolumeChanged() {
            volSlider.value = root.volumePct
        }
    }
}
