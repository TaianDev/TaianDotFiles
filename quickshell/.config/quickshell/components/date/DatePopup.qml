import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../../core"
import "../../services"
import "../network"
import "../shell"

PopupWindow {
    id: popup
    color: "transparent"

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    implicitWidth: 480
    implicitHeight: 360

    property bool isOpened: false
    property int currentTab: 0
    property var widgetRef: null
    property var anchorItem: null
    property var parentWindow: null

    property color bgDark: Theme.surface
    property color bgLighter: Theme.surfaceVariant
    property color accentGreen: Theme.primary
    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar

    visible: isOpened || shell.exitRunning

    grabFocus: isOpened

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.dateId)
                popup.isOpened = false
        }
    }

    function reposition() {
        if (!anchorItem || !parentWindow)
            return
        const pos = anchorItem.mapToItem(parentWindow.contentItem, 0, anchorItem.height)
        const ax = pos.x + anchorItem.width / 2 - implicitWidth / 2
        anchor.window = parentWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, implicitWidth, implicitHeight)
        anchor.updateAnchor()
    }

    onIsOpenedChanged: {
        if (!isOpened)
            PopupManager.notifyClosed(PopupManager.dateId)

        if (isOpened) {
            reposition()
            shell.active = true
        } else {
            shell.active = false
        }
    }

    onVisibleChanged: {
        if (visible) {
            reposition()
        } else if (popup.isOpened && !shell.exitRunning) {
            popup.isOpened = false
        }
    }

    PopupEscCapture {
        active: popup.isOpened
        popupId: PopupManager.dateId

        PopupEnterExit {
            id: shell
            anchors.fill: parent
            active: popup.isOpened
            cornerRadius: 16
            originH: Item.Center
            originV: Item.Top

            RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.preferredWidth: 120
                Layout.fillHeight: true
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Calendar", icon: "calendar.svg", index: 0 },
                            { name: "Stopwatch", icon: "stopwatch.svg", index: 1 },
                            { name: "Timer", icon: "timer.svg", index: 2 }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: 12
                            color: popup.currentTab === modelData.index
                                   ? Theme.alpha(Theme.primary, 0.18)
                                   : (btnMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.05) : "transparent")

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                SvgIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    source: popup.iconsPath + modelData.icon
                                    size: 20
                                    tint: popup.currentTab === modelData.index ? popup.textMain : popup.textMuted
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.name
                                    color: popup.currentTab === modelData.index ? popup.textMain : popup.textMuted
                                    font.pixelSize: 11
                                }
                            }
                            MouseArea {
                                id: btnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popup.currentTab = modelData.index
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }

                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.alpha(Theme.outline, 0.25)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                CalendarTab {
                    anchors.fill: parent
                    textMain: popup.textMain
                    textMuted: popup.textMuted
                    accentGreen: popup.accentGreen
                    bgDark: popup.bgDark
                    property bool isActive: popup.currentTab === 0
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                StopwatchTab {
                    anchors.fill: parent
                    textMain: popup.textMain
                    bgLighter: popup.bgLighter
                    widgetRef: popup.widgetRef
                    property bool isActive: popup.currentTab === 1
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                TimerTab {
                    anchors.fill: parent
                    textMain: popup.textMain
                    bgLighter: popup.bgLighter
                    widgetRef: popup.widgetRef
                    property bool isActive: popup.currentTab === 2
                    opacity: isActive ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }
            }
        }
    }
    }
}
