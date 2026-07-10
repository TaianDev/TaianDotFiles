pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../network"
import "../shell"
import "."

PanelWindow {
    id: panel

    required property var screen

    readonly property bool open: NotificationService.panelOpen
    readonly property int panelWidth: 360
    readonly property int edgeMargin: 14
    property real barPopupTopY: 42
    readonly property int panelVerticalMargin: Math.round((barPopupTopY + edgeMargin) / 2)

    readonly property var sortedNotifications: {
        const _v = NotificationService.listVersion
        const list = NotificationService.notifications.values.slice()
        list.sort((a, b) => NotificationService.receivedAt(b) - NotificationService.receivedAt(a))
        return list
    }

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: panel.panelVerticalMargin
        bottom: panel.panelVerticalMargin
        right: panel.edgeMargin
    }

    implicitWidth: panel.panelWidth

    color: "transparent"
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_notifications_" + screen.name
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: open

    PopupEscCapture {
        active: panel.open
        popupId: PopupManager.notificationsId

        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                radius: 22
                color: Theme.surface
                border.width: 1
                border.color: Theme.outlineVariant
                clip: true

                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 10
                    radius: 28
                    samples: 32
                    color: Theme.alpha(Theme.colorShadow, 0.42)
                }

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 48

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: "Notifications"
                                color: Theme.inkSurf
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Item {
                                visible: panel.sortedNotifications.length > 0
                                Layout.preferredWidth: clearLabel.implicitWidth + 8
                                Layout.preferredHeight: 28

                                Text {
                                    id: clearLabel
                                    anchors.centerIn: parent
                                    text: "Clear All"
                                    color: clearMa.containsMouse ? Theme.primary : Theme.inkSurfVar
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    opacity: clearMa.containsMouse ? 1 : 0.85
                                }

                                MouseArea {
                                    id: clearMa
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.dismissAll()
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                radius: 14
                                color: closePanelMa.containsMouse
                                       ? Theme.outlineVariant
                                       : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Theme.inkSurfVar
                                    font.pixelSize: 18
                                }

                                MouseArea {
                                    id: closePanelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.closePanel()
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outlineVariant
                    }

                    Item {
                        width: parent.width
                        height: parent.height - 49

                        ListView {
                            id: notifList
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            anchors.topMargin: 10
                            anchors.bottomMargin: 10
                            spacing: 8
                            clip: true
                            model: panel.sortedNotifications
                            boundsBehavior: Flickable.StopAtBounds

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                            }

                            add: Transition {
                                NumberAnimation {
                                    properties: "opacity,scale"
                                    from: 0.96
                                    to: 1.0
                                    duration: 220
                                    easing.type: Easing.OutCubic
                                }
                            }

                            remove: Transition {
                                NumberAnimation {
                                    properties: "opacity,scale"
                                    to: 0.0
                                    duration: 160
                                    easing.type: Easing.InCubic
                                }
                            }

                            displaced: Transition {
                                NumberAnimation {
                                    properties: "y"
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }

                            delegate: NotificationCard {
                                required property var modelData
                                required property int index
                                width: notifList.width
                                notification: modelData
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            width: parent.width - 48
                            visible: panel.sortedNotifications.length === 0
                            opacity: visible ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            SvgIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                source: AppPaths.iconsDir + "notifications.svg"
                                size: 32
                                tint: Theme.inkSurfVar
                                opacity: 0.28
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No Notifications"
                                color: Theme.inkSurfVar
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                text: "New alerts will show up here"
                                color: Theme.inkSurfVar
                                font.pixelSize: 11
                                opacity: 0.65
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
    }
}
