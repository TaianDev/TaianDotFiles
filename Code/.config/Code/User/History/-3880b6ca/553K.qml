import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    
    height: 32 
    // El ancho se anima automáticamente siguiendo al layout interno
    implicitWidth: mainLayout.width + 28
    radius: height / 2
    color: widgetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08) 
    Behavior on color { ColorAnimation { duration: 150 } }

    property string tempString: "..."

    // ─── ESTADO GLOBAL DEL CRONÓMETRO ───
    property bool swRunning: false
    property int swElapsedMs: 0
    property bool showSwControls: false

    // Este es el motor real del cronómetro
    Timer {
        id: swTimer
        interval: 50
        running: root.swRunning
        repeat: true
        onTriggered: root.swElapsedMs += 50
    }

    // Auto-oculta los controles después de 3.5 segundos de haberlo iniciado
    Timer {
        id: autoHideTimer
        interval: 3500 
        onTriggered: root.showSwControls = false
    }

    onSwRunningChanged: {
        // Al arrancar, muestra los controles y arranca el temporizador de auto-ocultado
        if (swRunning) {
            root.showSwControls = true
            autoHideTimer.restart()
        }
    }

    function formatPillSW(ms) {
        let m = Math.floor(ms / 60000).toString().padStart(2, '0')
        let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
        return m + ":" + s
    }

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes 
    }

    Process {
        id: weatherScanner
        command: ["bash", "-c", "curl -s 'wttr.in/Lima?format=%c%t' | tr -d '+' | sed 's/  */ /g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let temp = this.text.trim()
                if (temp !== "") root.tempString = temp
            }
        }
    }

    Timer {
        interval: 1800000 
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: { weatherScanner.running = false; weatherScanner.running = true }
    }

    // ── GATILLO DEL MOUSE ──
    // Se coloca antes del Layout para que no bloquee los clics en los botones internos
    MouseArea {
        id: widgetMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                datePopup.isOpened = !datePopup.isOpened
            } else {
                // Clic Izquierdo: Si el cronómetro tiene datos, expande/contrae los controles
                if (root.swElapsedMs > 0) {
                    root.showSwControls = !root.showSwControls
                    if (root.showSwControls) autoHideTimer.stop() // Modo manual, no auto-ocultar
                } else {
                    datePopup.isOpened = !datePopup.isOpened
                }
            }
        }
    }

    // ─── INTERFAZ ANIMADA (DYNAMIC ISLAND) ───
    Item {
        id: mainLayout
        anchors.centerIn: parent
        height: 32
        
        // El ancho se ajusta dinámicamente según la vista activa
        width: root.showSwControls ? swView.implicitWidth : normalView.implicitWidth
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        // 1. VISTA NORMAL (Fecha/Clima + Punto rojo si está activo)
        RowLayout {
            id: normalView
            anchors.centerIn: parent
            opacity: root.showSwControls ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            spacing: 8

            // Punto de Grabación
            Rectangle {
                width: 8; height: 8; radius: 4; color: "#e06c75"
                visible: root.swElapsedMs > 0
                SequentialAnimation on opacity {
                    running: root.swRunning && normalView.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.2; duration: 600 }
                    NumberAnimation { from: 0.2; to: 1; duration: 600 }
                }
            }

            Text {
                text: Qt.formatDateTime(sysClock.date, "HH:mm • ddd, dd/MM") + " • " + root.tempString
                color: "#e5e5e5"
                font.pixelSize: 14
                font.bold: true
            }
        }

        // 2. VISTA CRONÓMETRO ACTIVO (Controles)
        RowLayout {
            id: swView
            anchors.centerIn: parent
            opacity: root.showSwControls ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            spacing: 12

            Rectangle {
                width: 8; height: 8; radius: 4; color: "#e06c75"
                SequentialAnimation on opacity {
                    running: root.swRunning && swView.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.2; duration: 600 }
                    NumberAnimation { from: 0.2; to: 1; duration: 600 }
                }
            }

            Text {
                text: root.formatPillSW(root.swElapsedMs)
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                font.family: "monospace" // Fuente monoespaciada para evitar saltos en los números
            }

            // Botón Eliminar / Reset
            Rectangle {
                width: 24; height: 24; radius: 6; color: Qt.rgba(1,1,1,0.1)
                Text { anchors.centerIn: parent; text: "🗑"; color: Qt.rgba(1,1,1,0.7); font.pixelSize: 12 }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.swRunning = false; root.swElapsedMs = 0; root.showSwControls = false
                    }
                }
            }

            // Botón Play / Pausa
            Rectangle {
                width: 24; height: 24; radius: 6; color: Qt.rgba(224/255, 108/255, 117/255, 0.2)
                Text {
                    anchors.centerIn: parent
                    text: root.swRunning ? "⏸" : "▶"
                    color: "#e06c75"; font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.swRunning = !root.swRunning
                }
            }
        }
    }

    // Le pasamos la referencia de este widget al popup
    DatePopup {
        id: datePopup
        widgetRef: root 
    }
}