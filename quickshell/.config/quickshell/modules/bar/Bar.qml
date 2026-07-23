import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../core"
import "../../services"
import "../../components"
import "./widgets"
import "../notifications"
import "../network"
import "../network/popup"
import "../date"
import "../music"
import "../tray"

PanelWindow {
    id: flareBar

    required property var modelData

    screen: modelData

    readonly property string primaryMonitorName: "HDMI-A-1"
    readonly property bool isPrimary: modelData.name === primaryMonitorName
    readonly property bool isFocused: {
        const focused = Hyprland.focusedMonitor?.name ?? ""
        return focused === "" || focused === modelData.name
    }
    readonly property int barHeight: 40
    readonly property int flareRadius: 20
    readonly property int edgeMargin: 10
    readonly property int sectionSpacing: 10
    readonly property int barPopupGap: 8

    readonly property real barPopupTopY: {
        const pos = dateWidget.mapToItem(flareBar.contentItem, 0, dateWidget.height)
        return pos.y + barPopupGap
    }

    anchors { top: true; left: true; right: true }
    implicitHeight: barHeight + flareRadius + 13
    exclusiveZone: barHeight
    WlrLayershell.namespace: "flare_bar_" + modelData.name
    color: "transparent"
    mask: Region { item: mainBody }

    Item {
        id: barShadowHost
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: flareBar.barHeight + flareBar.flareRadius

        Rectangle {
            id: mainBody
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: flareBar.barHeight
            color: Theme.background
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        Shape {
            anchors.top: mainBody.bottom
            anchors.left: parent.left
            width: flareBar.flareRadius; height: flareBar.flareRadius
            antialiasing: true
            layer.enabled: true; layer.samples: 8
            ShapePath {
                fillColor: Theme.background; strokeWidth: 0
                startX: 0; startY: 0
                PathLine { x: flareBar.flareRadius; y: 0 }
                PathQuad { x: 0; y: flareBar.flareRadius; controlX: 0; controlY: 0 }
            }
        }

        Shape {
            anchors.top: mainBody.bottom
            anchors.right: parent.right
            width: flareBar.flareRadius; height: flareBar.flareRadius
            antialiasing: true
            layer.enabled: true; layer.samples: 8
            ShapePath {
                fillColor: Theme.background; strokeWidth: 0
                startX: 0; startY: 0
                PathQuad {
                    x: flareBar.flareRadius; y: flareBar.flareRadius
                    controlX: flareBar.flareRadius; controlY: 0
                }
                PathLine { x: flareBar.flareRadius; y: 0 }
                PathLine { x: 0; y: 0 }
            }
        }
    }

    DropShadow {
        anchors.fill: barShadowHost
        horizontalOffset: 0; verticalOffset: 3
        radius: 10; samples: 16
        color: Qt.rgba(0, 0, 0, 0.4)
        source: barShadowHost
        transparentBorder: true
    }

    Item {
        id: barContent
        z: 1
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: flareBar.barHeight
        anchors.leftMargin: flareBar.edgeMargin
        anchors.rightMargin: flareBar.edgeMargin

        Row {
            id: leftRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: flareBar.sectionSpacing

            ArchLogo { }

            WorkspacePills {
                id: workspacePills
                outputName: flareBar.modelData.name
                primaryMonitorName: flareBar.primaryMonitorName
            }

            Loader {
                active: !flareBar.isPrimary
                sourceComponent: SystemPill { }
            }

            Item {
                id: musicSlot
                visible: flareBar.isPrimary
                width: visible ? music.implicitWidth : 0
                height: visible ? music.implicitHeight : 0

                CavaBackdrop {
                    anchors.centerIn: parent
                    width: music.implicitWidth; height: music.implicitHeight
                    radius: music.capsuleHeight / 2
                    shown: music.player !== null
                    animating: music.playing
                }

                MusicWidget {
                    id: music
                    anchors.centerIn: parent
                }
            }

            Loader {
                active: flareBar.isPrimary
                sourceComponent: compBatteryPill
            }

            NotificationPill {
                visible: flareBar.isPrimary
            }

            TrayWidget {
                id: trayWidget
                visible: flareBar.isPrimary
                hostWindow: flareBar
            }

            ScreenshotPill {
                visible: flareBar.isPrimary
            }
        }

        DateWidget {
            id: dateWidget
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            hostWindow: flareBar
        }

        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: flareBar.sectionSpacing

            Loader {
                active: flareBar.isPrimary
                sourceComponent: SystemPill { }
            }

            Loader {
                active: !flareBar.isPrimary
                sourceComponent: compBatteryPill
            }

            NetworkPill {
                id: networkPill
                hostWindow: flareBar
            }

            PowerPill { }
        }
    }

    Component { id: compBatteryPill; BatteryPill { } }

    Connections {
        target: PopupManager
        function onToggleMusicRequested() {
            if (!flareBar.isPrimary) return
            music.togglePopup()
        }
        function onToggleNetworkRequested() {
            if (!flareBar.isFocused) return
            networkPill.togglePopup()
        }
        function onToggleDateRequested() {
            if (!flareBar.isFocused) return
            dateWidget.togglePopup()
        }
    }

    Loader {
        active: flareBar.isPrimary
        sourceComponent: Item {
            MusicPopup {
                widgetRef: music
                parentWindow: flareBar
            }
            TrayPopup {
                widgetRef: trayWidget
                parentWindow: flareBar
            }
            NotificationPanel {
                screen: flareBar.modelData
                barPopupTopY: flareBar.barPopupTopY
            }
            NotificationPopups {
                screen: flareBar.modelData
                barPopupTopY: flareBar.barPopupTopY
            }
        }
    }
}
