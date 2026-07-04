import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popup
    color: "transparent"

    implicitWidth: 480
    implicitHeight: 360

    anchors {
        top: true
        right: true
    }
    
    margins {
        top: 48
        right: 16
    }
    
    exclusiveZone: 0

    WlrLayershell.namespace: "date_popup"
    WlrLayershell.layer: WlrLayer.Top

    property bool isOpened: false
    property int currentTab: 0

    // Paleta Centralizada
    property color bgDark: "#1e1e1e"
    property color bgLighter: "#2d2d2d"
    property color accentGreen: "#b4db92"
    property color textMain: "#ffffff"
    property color textMuted: "#888888"

    visible: isOpened || slideAnim.running

    Item {
        id: mainWrapper
        anchors.fill: parent

        y: popup.isOpened ? 0 : -20
        opacity: popup.isOpened ? 1 : 0
        Behavior on y { NumberAnimation { id: slideAnim; duration: 250; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            color: popup.bgDark
            radius: 16
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ─── BARRA LATERAL ───
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
                                { name: "Calendario", icon: "📅", index: 0 },
                                { name: "Cronómetro", icon: "⏱️", index: 1 },
                                { name: "Temporizador", icon: "⏳", index: 2 }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 12
                                color: popup.currentTab === modelData.index ? Qt.rgba(180/255, 219/255, 146/255, 0.15)
                                                                              : (btnMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        font.pixelSize: 18
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
                        color: Qt.rgba(1, 1, 1, 0.05)
                    }
                }

                // ─── IMPORTACIÓN DINÁMICA DE MÓDULOS ───
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: popup.currentTab

                    CalendarTab {
                        textMain: popup.textMain
                        textMuted: popup.textMuted
                        accentGreen: popup.accentGreen
                        bgDark: popup.bgDark
                    }
                    
                    StopwatchTab {
                        textMain: popup.textMain
                        bgLighter: popup.bgLighter
                    }
                    
                    TimerTab {
                        textMain: popup.textMain
                        bgLighter: popup.bgLighter
                    }
                }
            }
        }
    }
}