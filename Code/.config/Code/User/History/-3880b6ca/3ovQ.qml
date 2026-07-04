import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    
    height: 32 
    implicitWidth: mainLayout.width + 28
    radius: height / 2
    color: widgetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08) 
    Behavior on color { ColorAnimation { duration: 150 } }

    property string tempString: "..."
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    // ─── INSTANCIAS / CONCURRENCIA DE LA ISLAND ───
    property int activeInstance: 1 // 1 = Cronómetro, 2 = Temporizador
    property string currentViewState: tmEndedNotification ? "notification" : 
                                      showSwControls ? "stopwatch" : 
                                      showTmControls ? "timer" : "normal"

    // ─── ESTADO ELEVADO: CRONÓMETRO ───
    property bool swRunning: false
    property int swElapsedMs: 0
    property bool showSwControls: false

    Timer {
        id: swTimer
        interval: 50; running: root.swRunning; repeat: true
        onTriggered: root.swElapsedMs += 50
    }

    // ─── ESTADO ELEVADO: TEMPORIZADOR ───
    property int tmH: 0
    property int tmM: 0
    property int tmS: 0
    property int tmTotalSecs: 0
    property bool tmActive: false
    property bool tmRunning: false
    property bool tmEndedNotification: false
    property bool showTmControls: false

    Timer {
        id: tmTimer
        interval: 1000; running: root.tmRunning; repeat: true
        onTriggered: {
            if (root.tmTotalSecs > 0) {
                root.tmTotalSecs--
            } else {
                root.tmRunning = false
                root.tmActive = false
                root.triggerTimerEnded()
            }
        }
    }

    Timer {
        id: dismissNotificationTimer
        interval: 5000
        onTriggered: root.tmEndedNotification = false
    }

    function triggerTimerEnded() {
        root.showTmControls = false
        root.showSwControls = false
        root.tmEndedNotification = true
        dismissNotificationTimer.restart()
    }

    Timer { id: autoHideSw; interval: 3500; onTriggered: root.showSwControls = false }
    Timer { id: autoHideTm; interval: 3500; onTriggered: root.showTmControls = false }

    onSwRunningChanged: { if (swRunning) { root.activeInstance = 1; root.showSwControls = true; root.showTmControls = false; autoHideSw.restart() } }
    onTmRunningChanged: { if (tmRunning) { root.activeInstance = 2; root.showTmControls = true; root.showSwControls = false; autoHideTm.restart() } }

    function formatPillSW(ms) {
        let m = Math.floor(ms / 60000).toString().padStart(2, '0')
        let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
        return m + ":" + s
    }

    function formatPillTM(secs) {
        let h = Math.floor(secs / 3600)
        let m = Math.floor((secs % 3600) / 60)
        let s = secs % 60
        if (h > 0) return h + ":" + m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
        return m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
    }

    SystemClock { id: sysClock; precision: SystemClock.Minutes }

    Process {
        id: weatherScanner
        command: ["bash", "-c", "curl -s 'wttr.in/Lima?format=%c%t' | tr -d '+' | sed 's/  */ /g'"]
        stdout: StdioCollector { onStreamFinished: { let temp = this.text.trim(); if (temp !== "") root.tempString = temp } }
    }
    Timer { interval: 1800000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { weatherScanner.running = false; weatherScanner.running = true } }

    // ─── GESTOS Y CLICS ───
    MouseArea {
        id: widgetMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real startX: 0
        property bool dragDetected: false

        onPressed: (mouse) => {
            startX = mouse.x
            dragDetected = false
        }

        onPositionChanged: (mouse) => {
            if (!dragDetected && (mouse.x - startX > 40)) {
                dragDetected = true
                let swIsActive = (root.swElapsedMs > 0 || root.swRunning)
                if (swIsActive && root.tmActive) {
                    root.activeInstance = (root.activeInstance === 1) ? 2 : 1
                    
                    if (root.showSwControls || root.showTmControls) {
                        root.showSwControls = (root.activeInstance === 1)
                        root.showTmControls = (root.activeInstance === 2)
                    }
                }
            }
        }

        onClicked: (mouse) => {
            if (dragDetected) return
            if (mouse.button === Qt.RightButton) {
                datePopup.isOpened = !datePopup.isOpened
            } else {
                if (root.tmEndedNotification) {
                    root.tmEndedNotification = false
                    return
                }
                if (root.activeInstance === 1 && (root.swElapsedMs > 0 || root.swRunning)) {
                    root.showSwControls = !root.showSwControls
                    root.showTmControls = false
                    autoHideSw.stop()
                } else if (root.activeInstance === 2 && root.tmActive) {
                    root.showTmControls = !root.showTmControls
                    root.showSwControls = false
                    autoHideTm.stop()
                } else {
                    datePopup.isOpened = !datePopup.isOpened
                }
            }
        }
    }

    // ─── INTERFAZ VISUAL: DYNAMIC ISLAND ───
    Item {
        id: mainLayout
        anchors.centerIn: parent
        height: 32
        
        width: currentViewState === "notification" ? notificationView.implicitWidth :
               currentViewState === "stopwatch" ? swView.implicitWidth :
               currentViewState === "timer" ? tmView.implicitWidth : normalView.implicitWidth
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }

        // 🌟 VISTA 1: NORMAL (Fecha + Iconos de Background concurrentes)
        RowLayout {
            id: normalView
            anchors.centerIn: parent
            opacity: root.currentViewState === "normal" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 8

            // Contenedor modular de iconos en segundo plano
            RowLayout {
                spacing: 6
                visible: root.swElapsedMs > 0 || root.tmActive

                // Punto Rojo (Cronómetro)
                Rectangle {
                    id: swDotIndicator
                    width: 8; height: 8; radius: 4; color: "#e06c75"
                    visible: root.swElapsedMs > 0

                    SequentialAnimation {
                        id: swDotBlinker
                        running: root.swRunning && root.currentViewState === "normal" && swDotIndicator.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: swDotIndicator; property: "opacity"; from: 1; to: 0.2; duration: 600 }
                        NumberAnimation { target: swDotIndicator; property: "opacity"; from: 0.2; to: 1; duration: 600 }
                        onRunningChanged: { if (!running) swDotIndicator.opacity = 1 }
                    }
                }
                
                // Reloj de Arena (Temporizador)
                Item {
                    id: tmIconIndicator
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    visible: root.tmActive

                    Image {
                        anchors.fill: parent
                        source: root.iconsPath + "sand-clock.svg"
                        sourceSize.width: 12
                        sourceSize.height: 12
                        fillMode: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: "#ffffff" }
                    }

                    SequentialAnimation {
                        id: tmIconBlinker
                        running: root.tmRunning && root.currentViewState === "normal" && tmIconIndicator.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: tmIconIndicator; property: "opacity"; from: 1; to: 0.3; duration: 600 }
                        NumberAnimation { target: tmIconIndicator; property: "opacity"; from: 0.3; to: 1; duration: 600 }
                        onRunningChanged: { if (!running) tmIconIndicator.opacity = 1 }
                    }
                }
            }

            Text {
                text: Qt.formatDateTime(sysClock.date, "HH:mm • ddd, dd/MM") + " • " + root.tempString
                color: "#e5e5e5"; font.pixelSize: 14; font.bold: true
            }
        }

        // 🌟 VISTA 2: CONTROLES DEL CRONÓMETRO EXPANSIBLES
        RowLayout {
            id: swView
            anchors.centerIn: parent
            opacity: root.currentViewState === "stopwatch" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 12

            Rectangle {
                id: swActiveDot
                width: 8; height: 8; radius: 4; color: "#e06c75"
                SequentialAnimation {
                    running: root.swRunning && root.currentViewState === "stopwatch"
                    loops: Animation.Infinite
                    NumberAnimation { target: swActiveDot; property: "opacity"; from: 1; to: 0.2; duration: 600 }
                    NumberAnimation { target: swActiveDot; property: "opacity"; from: 0.2; to: 1; duration: 600 }
                    onRunningChanged: { if (!running) swActiveDot.opacity = 1 }
                }
            }

            Text { 
                text: root.formatPillSW(root.swElapsedMs)
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                font.family: "monospace" 
            }
            
            // Botón Eliminar
            Rectangle { 
                width: 24
                height: 24
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.1)
                
                Text { 
                    anchors.centerIn: parent
                    text: "🗑"
                    color: "#ffffff"
                    font.pixelSize: 11 
                }
                
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { 
                        root.swRunning = false
                        root.swElapsedMs = 0
                        root.showSwControls = false 
                    } 
                } 
            }
            
            // Botón Play/Pause
            Rectangle { 
                width: 24
                height: 24
                radius: 6
                color: Qt.rgba(224/255, 108/255, 117/255, 0.2)
                
                Text { 
                    anchors.centerIn: parent
                    text: root.swRunning ? "⏸" : "▶"
                    color: "#e06c75"
                    font.pixelSize: 11 
                }
                
                MouseArea { 
                    anchors.fill: parent
                    onClicked: root.swRunning = !root.swRunning 
                } 
            }
        }

        // 🌟 VISTA 3: CONTROLES DEL TEMPORIZADOR EXPANSIBLES
        RowLayout {
            id: tmView
            anchors.centerIn: parent
            opacity: root.currentViewState === "timer" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 12

            Image { 
                source: root.iconsPath + "sand-clock.svg"
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                sourceSize.width: 14
                sourceSize.height: 14
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: "#ffffff" }
            }

            Text { 
                text: root.formatPillTM(root.tmTotalSecs)
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                font.family: "monospace" 
            }
            
            // Botón Cancelar Temporizador
            Rectangle { 
                width: 24
                height: 24
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.1)
                
                Text { 
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#ffffff"
                    font.pixelSize: 11 
                }
                
                MouseArea { 
                    anchors.fill: parent
                    onClicked: { 
                        root.tmRunning = false
                        root.tmActive = false
                        root.tmTotalSecs = 0
                        root.showTmControls = false 
                    } 
                } 
            }
            
            // Botón Play/Pause Temporizador
            Rectangle { 
                width: 24
                height: 24
                radius: 6
                color: Qt.rgba(180/255, 219/255, 146/255, 0.2)
                
                Text { 
                    anchors.centerIn: parent
                    text: root.tmRunning ? "⏸" : "▶"
                    color: "#b4db92"
                    font.pixelSize: 11 
                }
                
                MouseArea { 
                    anchors.fill: parent
                    onClicked: root.tmRunning = !root.tmRunning 
                } 
            }
        }

        // 🌟 VISTA 4: NOTIFICACIÓN GLOBAL
        RowLayout {
            id: notificationView
            anchors.centerIn: parent
            opacity: root.currentViewState === "notification" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 10

            Image { 
                source: root.iconsPath + "end-clock.svg"
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                sourceSize.width: 16
                sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: "#ffffff" }
            }
            
            Text { 
                text: "Time's up!"
                color: "#e06c75"
                font.pixelSize: 14
                font.bold: true 
            }
        }
    }

    DatePopup { 
        id: datePopup
        widgetRef: root 
    }
}