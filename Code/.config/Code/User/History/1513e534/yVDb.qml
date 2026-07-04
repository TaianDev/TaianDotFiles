import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color textMain: "#ffffff"
    property color bgLighter: "#2d2d2d"
    
    // Conexión con el estado global de la Dynamic Island
    property var widgetRef: null

    property int h: widgetRef ? widgetRef.tmH : 0
    property int m: widgetRef ? widgetRef.tmM : 0
    property int s: widgetRef ? widgetRef.tmS : 0
    property int totalSecs: widgetRef ? widgetRef.tmTotalSecs : 0
    property bool isActive: widgetRef ? widgetRef.tmActive : false
    property bool isRunning: widgetRef ? widgetRef.tmRunning : false

    function setQuick(mins) {
        if (!widgetRef) return
        widgetRef.tmH = Math.floor(mins / 60)
        widgetRef.tmM = mins % 60
        widgetRef.tmS = 0
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
        widgetRef.tmActive = true
        widgetRef.tmRunning = true
    }

    Item {
        anchors.fill: parent
        anchors.margins: 20

        // ─── ESTADO 1: CONFIGURACIÓN ───
        Item {
            anchors.fill: parent
            opacity: root.isActive ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            ColumnLayout {
                anchors.centerIn: parent; spacing: 16

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
                    Layout.alignment: Qt.AlignHCenter; spacing: 12
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
                                            if (!widgetRef) return
                                            if (index === 0) widgetRef.tmH++
                                            else if (index === 1) widgetRef.tmM = (widgetRef.tmM + 1) % 60
                                            else widgetRef.tmS = (widgetRef.tmS + 1) % 60
                                            widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
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
                                            if (!widgetRef) return
                                            if (index === 0 && widgetRef.tmH > 0) widgetRef.tmH--
                                            else if (index === 1 && widgetRef.tmM > 0) widgetRef.tmM--
                                            else if (index === 2 && widgetRef.tmS > 0) widgetRef.tmS--
                                            widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10; width: 120; height: 40; radius: 20; color: "#7287a3"
                    Text { anchors.centerIn: parent; text: "Empezar"; color: "#ffffff"; font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (widgetRef && widgetRef.tmTotalSecs > 0) { widgetRef.tmActive = true; widgetRef.tmRunning = true } } }
                }
            }
        }

        // ─── ESTADO 2: CUENTA REGRESIVA ───
        Item {
            anchors.fill: parent
            opacity: root.isActive ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

            ColumnLayout {
                anchors.centerIn: parent; spacing: 30
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.floor(root.totalSecs / 3600).toString().padStart(2, '0') + ":" + Math.floor((root.totalSecs % 3600) / 60).toString().padStart(2, '0') + ":" + (root.totalSecs % 60).toString().padStart(2, '0')
                    color: root.textMain; font.pixelSize: 54; font.weight: Font.Thin
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter; spacing: 16

                    Rectangle {
                        width: 120; height: 40; radius: 20; color: root.bgLighter
                        Text { anchors.centerIn: parent; text: root.isRunning ? "Pausar" : "Reanudar"; color: "#ffffff"; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (widgetRef) widgetRef.tmRunning = !widgetRef.tmRunning } }
                    }

                    Rectangle {
                        width: 120; height: 40; radius: 20; color: "#e06c75"
                        Text { anchors.centerIn: parent; text: "Cancelar"; color: "#ffffff"; font.bold: true }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { 
                                if (widgetRef) {
                                    widgetRef.tmRunning = false; widgetRef.tmActive = false 
                                    widgetRef.tmTotalSecs = 0; widgetRef.tmH = 0; widgetRef.tmM = 0; widgetRef.tmS = 0 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}