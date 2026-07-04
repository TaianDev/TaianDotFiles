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

    anchors { top: true; right: true }
    margins { top: 48; right: 16 }
    exclusiveZone: 0

    WlrLayershell.namespace: "date_popup"
    WlrLayershell.layer: WlrLayer.Top

    property bool isOpened: false
    property int currentTab: 0
    
    // 🌟 Recibe la referencia del padre y la almacena
    property var widgetRef: null 

    property color bgDark: "#1e1e1e"
    property color bgLighter: "#2d2d2d"
    property color accentGreen: "#b4db92"
    property color textMain: "#ffffff"
    property color textMuted: "#888888"

    visible: isOpened || bubbleAnim.running

    onIsOpenedChanged: {
        if (isOpened) bubbleAnim.restart()
        else bubbleOutAnim.restart()
    }

    Item {
        id: mainWrapper
        anchors.fill: parent
        opacity: 0; scale: 0.88
        transformOrigin: Item.TopRight

        ParallelAnimation {
            id: bubbleAnim
            NumberAnimation { target: mainWrapper; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: mainWrapper; property: "scale"; from: 0.88; to: 1; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
        }
        ParallelAnimation {
            id: bubbleOutAnim
            NumberAnimation { target: mainWrapper; property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: mainWrapper; property: "scale"; from: 1; to: 0.88; duration: 150; easing.type: Easing.InCubic }
        }

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
                                Layout.fillWidth: true; Layout.preferredHeight: 60; radius: 12
                                color: popup.currentTab === modelData.index ? Qt.rgba(180/255, 219/255, 146/255, 0.15) : (btnMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")

                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { Layout.alignment: Qt.AlignHCenter; text: modelData.icon; font.pixelSize: 18 }
                                    Text { Layout.alignment: Qt.AlignHCenter; text: modelData.name; color: popup.currentTab === modelData.index ? popup.textMain : popup.textMuted; font.pixelSize: 11 }
                                }
                                MouseArea { id: btnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: popup.currentTab = modelData.index }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.05) }
                }

                // ─── PESTAÑAS ───
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true

                    CalendarTab {
                        anchors.fill: parent
                        textMain: popup.textMain; textMuted: popup.textMuted; accentGreen: popup.accentGreen; bgDark: popup.bgDark
                        property bool isActive: popup.currentTab === 0
                        opacity: isActive ? 1 : 0; visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }
                    
                    StopwatchTab {
                        anchors.fill: parent
                        textMain: popup.textMain; bgLighter: popup.bgLighter
                        
                        // 🌟 Se le envía la referencia del widget a la pestaña
                        widgetRef: popup.widgetRef 

                        property bool isActive: popup.currentTab === 1
                        opacity: isActive ? 1 : 0; visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }
                    
                    TimerTab {
                        anchors.fill: parent
                        textMain: popup.textMain; bgLighter: popup.bgLighter
                        property bool isActive: popup.currentTab === 2
                        opacity: isActive ? 1 : 0; visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                    }
                }
            }
        }
    }
}