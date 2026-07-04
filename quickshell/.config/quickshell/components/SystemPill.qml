import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    height: 28
    width: contentRow.implicitWidth + 24
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 0.5
    border.color: Qt.rgba(1, 1, 1, 0.12)

    property int cpuUsage:  0
    property int ramUsage:  0
    property int tempValue: 0

    // Estado interno CPU
    property int _lastTotal: 0
    property int _lastIdle:  0

    // ── FileViews — uno por archivo del sistema ───────────────
    FileView {
        id: memFile
        path: "/proc/meminfo"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        blockLoading: true
        watchChanges: false
    }

    FileView {
        id: tempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
        blockLoading: true
        watchChanges: false
    }

    // ── Timer de actualización ────────────────────────────────
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            memFile.reload()
            cpuFile.reload()
            tempFile.reload()

            // 1. RAM
            const memLines = memFile.text().split('\n')
            var memTotal = 1, memAvail = 0
            for (var i = 0; i < memLines.length; i++) {
                const l = memLines[i]
                if (l.startsWith("MemTotal:"))
                    memTotal = parseInt(l.replace(/[^0-9]/g, ''))
                else if (l.startsWith("MemAvailable:"))
                    memAvail = parseInt(l.replace(/[^0-9]/g, ''))
            }
            root.ramUsage = Math.round(((memTotal - memAvail) / memTotal) * 100)

            // 2. CPU
            const cpuLine = cpuFile.text().split('\n')[0]
            const parts = cpuLine.match(/\d+/g)
            if (parts && parts.length >= 4) {
                const idle  = parseInt(parts[3])
                var total = 0
                for (var j = 0; j < parts.length; j++) total += parseInt(parts[j])
                if (root._lastTotal > 0) {
                    const diffIdle  = idle  - root._lastIdle
                    const diffTotal = total - root._lastTotal
                    root.cpuUsage = diffTotal > 0
                        ? Math.round((1 - diffIdle / diffTotal) * 100)
                        : 0
                }
                root._lastTotal = total
                root._lastIdle  = idle
            }

            // 3. Temperatura
            const tempRaw = tempFile.text().trim()
            if (tempRaw.length > 0)
                root.tempValue = Math.round(parseInt(tempRaw) / 1000)
        }
    }

    // ── Contenido ─────────────────────────────────────────────
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 16

        ResourceMeter {
            value: root.cpuUsage
            iconPath: Qt.resolvedUrl("../assets/icons/cpu.svg")
            activeColor: "#89b4fa"
            suffix: "%"
        }
        ResourceMeter {
            value: root.ramUsage
            iconPath: Qt.resolvedUrl("../assets/icons/ram.svg")
            activeColor: "#a6e3a1"
            suffix: "%"
        }
        ResourceMeter {
            value: root.tempValue
            iconPath: Qt.resolvedUrl("../assets/icons/temperature.svg")
            activeColor: "#f38ba8"
            suffix: "°"
        }
    }
}
                                                                                