import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"
import "../../services"

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

    property int activeFieldIndex: -1

    function appendDigit(digit) {
        if (activeFieldIndex < 0) return
        const maxVal = activeFieldIndex === 0 ? 99 : 59
        let cur = 0
        if (activeFieldIndex === 0) cur = root.h
        else if (activeFieldIndex === 1) cur = root.m
        else cur = root.s
        let newVal = (cur * 10 + digit) % 100
        if (newVal > maxVal) newVal = digit
        root.setTimeVal(activeFieldIndex, newVal)
    }

    function backspaceField() {
        if (activeFieldIndex < 0) return
        let cur = 0
        if (activeFieldIndex === 0) cur = root.h
        else if (activeFieldIndex === 1) cur = root.m
        else cur = root.s
        root.setTimeVal(activeFieldIndex, Math.floor(cur / 10))
    }

    function selectField(idx) {
        activeFieldIndex = idx
    }

    function setQuick(mins) {
        if (!widgetRef) return
        widgetRef.tmH = Math.floor(mins / 60)
        widgetRef.tmM = mins % 60
        widgetRef.tmS = 0
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
        widgetRef.tmActive = true
        widgetRef.tmRunning = true
    }

    function updateTime(idx, delta) {
        if (!widgetRef) return
        if (idx === 0) {
            widgetRef.tmH = Math.max(0, Math.min(99, widgetRef.tmH + delta))
        } else if (idx === 1) {
            let newVal = widgetRef.tmM + delta
            if (newVal > 59) newVal = 0
            else if (newVal < 0) newVal = 59
            widgetRef.tmM = newVal
        } else if (idx === 2) {
            let newVal = widgetRef.tmS + delta
            if (newVal > 59) newVal = 0
            else if (newVal < 0) newVal = 59
            widgetRef.tmS = newVal
        }
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
    }

    function setTimeVal(idx, val) {
        if (!widgetRef) return
        if (idx === 0) widgetRef.tmH = Math.max(0, Math.min(99, val))
        else if (idx === 1) widgetRef.tmM = Math.max(0, Math.min(59, val))
        else if (idx === 2) widgetRef.tmS = Math.max(0, Math.min(59, val))
        widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS
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
                anchors.centerIn: parent
                spacing: 16

                Text { 
                    text: "Quick start"
                    color: root.textMain
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter 
                }

                GridLayout {
                    columns: 4
                    columnSpacing: 8
                    rowSpacing: 8
                    Layout.alignment: Qt.AlignHCenter
                    
                    Repeater {
                        model: [1, 2, 3, 5, 10, 15, 30, 60]
                        Rectangle {
                            width: 50
                            height: 32
                            radius: 8
                            
                            color: qsMa.containsMouse ? Qt.lighter(root.bgLighter, 1.3) : root.bgLighter
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text { 
                                anchors.centerIn: parent
                                text: modelData === 60 ? "1 h" : modelData + " m"
                                color: root.textMain 
                            }
                            
                            MouseArea { 
                                id: qsMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setQuick(modelData) 
                            }
                        }
                    }
                }

                Text { 
                    text: "Set timer"
                    color: root.textMain
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10 
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12
                    
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 60
                            height: 90
                            radius: 8
                            color: root.bgLighter
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    radius: 8
                                    color: plusMa.containsMouse ? (plusMa.pressed ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text { anchors.centerIn: parent; text: "+"; color: root.textMain; font.pixelSize: 18 }
                                    
                                    Timer { id: repPlus; interval: 80; repeat: true; onTriggered: root.updateTime(index, 1) }
                                    Timer { id: delPlus; interval: 400; onTriggered: repPlus.start() }
                                    
                                    MouseArea {
                                        id: plusMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: { root.updateTime(index, 1); delPlus.start() }
                                        onReleased: { delPlus.stop(); repPlus.stop() }
                                        onCanceled: { delPlus.stop(); repPlus.stop() }
                                    }
                                }
                                
Text {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: root.textMain
                                    font.pixelSize: 28
                                    text: {
                                        if (index === 0) return root.h.toString().padStart(2, '0')
                                        if (index === 1) return root.m.toString().padStart(2, '0')
                                        return root.s.toString().padStart(2, '0')
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: root.selectField(index)
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: "transparent"
                                        border.width: index === root.activeFieldIndex ? 1 : 0
                                        border.color: Theme.primary
                                        visible: index === root.activeFieldIndex
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    radius: 8
                                    color: minusMa.containsMouse ? (minusMa.pressed ? Theme.alpha(Theme.inkSurf, 0.15) : Theme.alpha(Theme.inkSurf, 0.08)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Text { anchors.centerIn: parent; text: "-"; color: root.textMain; font.pixelSize: 18 }
                                    
                                    Timer { id: repMinus; interval: 80; repeat: true; onTriggered: root.updateTime(index, -1) }
                                    Timer { id: delMinus; interval: 400; onTriggered: repMinus.start() }
                                    
                                    MouseArea {
                                        id: minusMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: { root.updateTime(index, -1); delMinus.start() }
                                        onReleased: { delMinus.stop(); repMinus.stop() }
                                        onCanceled: { delMinus.stop(); repMinus.stop() }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 10
                    width: 120
                    height: 40
                    radius: 20
                    
                    color: empMa.containsMouse ? Theme.alpha(Theme.secondary, 0.9) : Theme.secondaryContainer
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "Start"
                        color: Theme.inkSecCont
                        font.bold: true 
                    }
                    
                    MouseArea { 
                        id: empMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { 
                            if (widgetRef) { 
                                // 🌟 CORRECCIÓN CLAVE: Regenerar el total de segundos a partir
                                // de las horas, minutos y segundos antes de arrancar.
                                widgetRef.tmTotalSecs = widgetRef.tmH * 3600 + widgetRef.tmM * 60 + widgetRef.tmS;
                                
                                if (widgetRef.tmTotalSecs > 0) {
                                    widgetRef.tmActive = true; 
                                    widgetRef.tmRunning = true; 
                                }
                            } 
                        } 
                    }
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
                anchors.centerIn: parent
                spacing: 30
                
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Math.floor(root.totalSecs / 3600).toString().padStart(2, '0') + ":" + Math.floor((root.totalSecs % 3600) / 60).toString().padStart(2, '0') + ":" + (root.totalSecs % 60).toString().padStart(2, '0')
                    color: root.textMain
                    font.pixelSize: 54
                    font.weight: Font.Thin
                }
                
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16

                    Rectangle {
                        width: 120
                        height: 40
                        radius: 20
                        
                        color: prMa.containsMouse ? Qt.lighter(root.bgLighter, 1.3) : root.bgLighter
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text { 
                            anchors.centerIn: parent
                            text: root.isRunning ? "Pause" : "Resume"
                            color: Theme.inkSecCont
                            font.bold: true 
                        }
                        
                        MouseArea { 
                            id: prMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { if (widgetRef) widgetRef.tmRunning = !widgetRef.tmRunning } 
                        }
                    }

                    Rectangle {
                        width: 120
                        height: 40
                        radius: 20
                        
                        color: canMa.containsMouse ? Theme.alpha(Theme.err, 0.9) : Theme.errContainer
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text { 
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: Theme.inkSecCont
                            font.bold: true 
                        }
                        
                        MouseArea {
                            id: canMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { 
                                if (widgetRef) {
                                    widgetRef.tmRunning = false
                                    widgetRef.tmActive = false 
                                    widgetRef.tmTotalSecs = 0
                                    widgetRef.tmH = 0
                                    widgetRef.tmM = 0
                                    widgetRef.tmS = 0 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
