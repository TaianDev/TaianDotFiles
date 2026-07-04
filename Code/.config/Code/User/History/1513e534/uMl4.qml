import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color textMain: "#ffffff"
    property color bgLighter: "#2d2d2d"

    property int h: 0
    property int m: 0
    property int s: 0
    property int totalSecs: 0
    property bool running: false

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.totalSecs > 0) root.totalSecs--
            else root.running = false
        }
    }

    function setQuick(mins) {
        running = false
        h = Math.floor(mins / 60)
        m = mins % 60
        s = 0
        totalSecs = h * 3600 + m * 60 + s
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ESTADO 1: Configuración
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: !root.running

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Text { text: "Inicio rápido"; color: root.textMain; font.bold: true; Layout.alignment: Qt.AlignHCenter }

                GridLayout {
                    columns: 4; columnSpacing: 8; rowSpacing: 8; Layout.alignment: Qt.AlignHCenter
                    Repeater {
                        model: [1, 2, 3, 5, 10, 15, 30, 60]
                        Rectangle {
                            width: 50; height: 32; radius: 8; color: root.bgLighter
                            Text { anchors.centerIn: parent; text: modelData === 60 ? "1 h" : modelData + " m"; color: root.textMain }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setQuick(modelData) }
                        }
                    }
                }

                Text { text: "Establecer temporizador"; color: root.textMain; font.bold: true; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10 }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 60; height: 90; radius: 8; color: root.bgLighter
                            ColumnLayout {
                                anchors.fill: parent
                                Text {
                                    text: "+"; color: root.textMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (index === 0) root.h++
                                            else if (index === 1) root.m = (root.m + 1) % 60
                                            else root.s = (root.s + 1) % 60
                                            root.totalSecs = root.h * 3600 + root.m * 60 + root.s
                                        }
                                    }
                                }
                                Text {
                                    text: {
                                        if (index === 0) return root.h.toString().padStart(2, '0')
                                        if (index === 1) return root.m.toString().padStart(2, '0')
                                        return root.s.toString().padStart(2, '0')
                                    }
                                    color: root.textMain; font.pixelSize: 28; Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: "-"; color: root.textMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (index === 0 && root.h > 0) root.h--
                                            else if (index === 1 && root.m > 0) root.m--
                                            else if (index === 2 && root.s > 0) root.s--
                                            root.totalSecs = root.h * 3600 + root.m * 60 + root.s
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10; width: 120; height: 40; radius: 20
                    color: "#7287a3"
                    Text { anchors.centerIn: parent; text: "Empezar"; color: "#ffffff"; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (root.totalSecs > 0) root.running = true } }
                }
            }
        }

        // ESTADO 2: Corriendo
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            visible: root.running
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 30
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.floor(root.totalSecs / 3600).toString().padStart(2, '0') + ":" + Math.floor((root.totalSecs % 3600) / 60).toString().padStart(2, '0') + ":" + (root.totalSecs % 60).toString().padStart(2, '0')
                    color: root.textMain; font.pixelSize: 54; font.weight: Font.Thin
                }
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter; width: 120; height: 40; radius: 20
                    color: "#e06c75"
                    Text { anchors.centerIn: parent; text: "Cancelar"; color: "#ffffff"; font.bold: true }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.running = false; root.totalSecs = 0; root.h = 0; root.m = 0; root.s = 0 }
                    }
                }
            }
        }
    }
}