import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    
    height: 32 
    implicitWidth: layout.implicitWidth + 28
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.08) 
    
    property string tempString: "..."

    // ── 1. Reloj Nativo de Quickshell ──
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes 
    }

    // ── 2. Escáner de Temperatura y Emoji Dinámico ──
    Process {
        id: weatherScanner
        // %c nos da el emoji de la condición actual, %t la temperatura.
        // Usamos sed para colapsar espacios múltiples y dejar un formato limpio.
        command: ["bash", "-c", "curl -s 'wttr.in/Lima?format=%c%t' | tr -d '+' | sed 's/  */ /g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let temp = this.text.trim()
                if (temp !== "") {
                    root.tempString = temp
                }
            }
        }
    }

    // Actualiza el clima cada 30 minutos (1.800.000 ms)
    Timer {
        interval: 1800000 
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherScanner.running = false
            weatherScanner.running = true
        }
    }

    // ── 3. Interfaz Visual ──
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 0

        Text {
            // Une de forma limpia la fecha con el string dinámico (ej: ☀️ 19°C o ☁️ 15°C)
            text: Qt.formatDateTime(sysClock.date, "HH:mm • ddd, dd/MM") + " • " + root.tempString
            color: "#e5e5e5"
            font.pixelSize: 12
            font.bold: true
        }
    }
}