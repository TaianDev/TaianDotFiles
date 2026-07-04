import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "DatePopup.qml"
Rectangle {
    id: root
    height: 32
    implicitWidth: layout.implicitWidth + 28
    radius: height / 2
    color: widgetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
    Behavior on color { ColorAnimation { duration: 150 } }

    property string tempString: "..."

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
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherScanner.running = false
            weatherScanner.running = true
        }
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 0
        Text {
            text: Qt.formatDateTime(sysClock.date, "HH:mm • ddd, dd/MM") + " • " + root.tempString
            color: "#e5e5e5"
            font.pixelSize: 14
            font.bold: true
        }
    }

    // Gatillo para abrir/cerrar el popup
    MouseArea {
        id: widgetMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: {
            datePopup.isOpened = !datePopup.isOpened
        }
    }

    DatePopup {
        id: datePopup
    }
}