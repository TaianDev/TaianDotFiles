import QtQuick
import QtQuick.Controls
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
                    text: "Inicio rápido"
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
                    text: "Establecer temporizador"
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
                                    color: plusMa.containsMouse ? (plusMa.pressed ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)) : "transparent"
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
                                
TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    color: root.textMain
                                    font.pixelSize: 28
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter
                                    background: Item {} // Elimina la línea base nativa
                                    
                                    validator: IntValidator { bottom: 0; top: index === 0 ? 99 : 59 }
                                    
                                    property string stateText: {
                                        if (index === 0) return root.h.toString().padStart(2, '0')
                                        if (index === 1) return root.m.toString().padStart(2, '0')
                                        return root.s.toString().padStart(2, '0')
                                    }
                                    
                                    Component.onCompleted: text = stateText
                                    
                                    onStateTextChanged: { if (!activeFocus) text = stateText }
                                    
                                    // 🌟 SOLUCIÓN AL BUG DEL TEXTO EN BLANCO
                                    onEditingFinished: {
                                        // Si está vacío o es inválido, lo forzamos a 0
                                        let val = parseInt(text)
                                        if (isNaN(val) || text.trim() === "") {
                                            val = 0
                                        }
                                        
                                        // Actualizamos el estado global
                                        root.setTimeVal(index, val)
                                        
                                        // Forzamos el relleno visual con ceros ignorando el estado reactivo
                                        text = val.toString().padStart(2, '0')
                                        
                                        focus = false // Suelta el teclado
                                    }
                                    
                                    // Respaldo adicional: Si el usuario hace clic fuera sin presionar Enter
                                    onActiveFocusChanged: {
                                        if (!activeFocus) {
                                            let val = parseInt(text)
                                            if (isNaN(val) || text.trim() === "") val = 0
                                            text = val.toString().padStart(2, '0')
                                        }
                                    }
                                }
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    radius: 8
                                    color: minusMa.containsMouse ? (minusMa.pressed ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)) : "transparent"
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
                    
                    color: empMa.containsMouse ? Qt.lighter("#7287a3", 1.15) : "#7287a3"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    Text { 
                        anchors.centerIn: parent
                        text: "Empezar"
                        color: "#ffffff"
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
                            text: root.isRunning ? "Pausar" : "Reanudar"
                            color: "#ffffff"
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
                        
                        color: canMa.containsMouse ? Qt.lighter("#e06c75", 1.15) : "#e06c75"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        Text { 
                            anchors.centerIn: parent
                            text: "Cancelar"
                            color: "#ffffff"
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