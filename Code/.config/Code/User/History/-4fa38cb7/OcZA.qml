import QtQuick
import QtQuick.Layouts
import Quickshell           // Necesario para Fs.readFile()

Rectangle {
    id: root
    height: 28
    width: contentRow.implicitWidth + 24
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 0.5
    border.color: Qt.rgba(1, 1, 1, 0.12)
    clip: true

    property int cpuUsage: 0
    property int ramUsage: 0
    property int tempValue: 0

    property int _lastTotal: 0
    property int _lastIdle: 0

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 16

        ResourceMeter {
            value: root.cpuUsage
            iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/cpu.svg"
            activeColor: "#89b4fa"
            suffix: "%"
        }

        ResourceMeter {
            value: root.ramUsage
            iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/ram.svg"
            activeColor: "#a6e3a1"
            suffix: "%"
        }

        ResourceMeter {
            value: root.tempValue
            iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/temperature.svg"
            activeColor: "#f38ba8"
            suffix: "°"
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // 1. RAM
            try {
                var memInfo = Fs.readFile("/proc/meminfo");
                var lines = memInfo.split('\n');
                var memTotal = 1, memAvail = 0;
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("MemTotal:") === 0)
                        memTotal = parseInt(lines[i].replace(/[^0-9]/g, ''));
                    if (lines[i].indexOf("MemAvailable:") === 0)
                        memAvail = parseInt(lines[i].replace(/[^0-9]/g, ''));
                }
                root.ramUsage = Math.round(((memTotal - memAvail) / memTotal) * 100);
            } catch(e) {
                console.log("Error leyendo RAM:", e);
            }

            // 2. CPU
            try {
                var cpuStat = Fs.readFile("/proc/stat");
                var cpuLine = cpuStat.split('\n')[0];
                var parts = cpuLine.match(/\d+/g);
                if (parts && parts.length >= 4) {
                    var idle = parseInt(parts[3]);
                    var total = 0;
                    for (var j = 0; j < parts.length; j++) total += parseInt(parts[j]);

                    if (root._lastTotal > 0) {
                        var diffIdle = idle - root._lastIdle;
                        var diffTotal = total - root._lastTotal;
                        root.cpuUsage = Math.round((1000 * (diffTotal - diffIdle) / diffTotal + 5) / 10);
                    }
                    root._lastTotal = total;
                    root._lastIdle = idle;
                }
            } catch(e) {
                console.log("Error leyendo CPU:", e);
            }

            // 3. Temperatura
            try {
                // Ajusta la ruta si tu sensor tiene otro nombre (p.ej. /sys/class/hwmon/...)
                var tempRaw = Fs.readFile("/sys/class/thermal/thermal_zone0/temp");
                if (tempRaw.length > 0)
                    root.tempValue = Math.round(parseInt(tempRaw) / 1000);
            } catch(e) {
                console.log("Error leyendo temperatura:", e);
            }
        }
    }
}