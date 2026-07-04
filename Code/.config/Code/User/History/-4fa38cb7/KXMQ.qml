import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    height: 28
    width: contentRow.implicitWidth + 24
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.08)
    border.width: 0.5
    border.color: Qt.rgba(1, 1, 1, 0.12)
    clip: true

    // Variables de estado
    property int cpuUsage: 0
    property int ramUsage: 0
    property int tempValue: 0
    
    // Variables internas para calcular CPU
    property int _lastTotal: 0
    property int _lastIdle: 0

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 16

        ResourceMeter {
            value: root.cpuUsage
            iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/cpu.svg"
            activeColor: "#89b4fa" // Azul
            suffix: "%"
        }

        ResourceMeter {
            value: root.ramUsage
            iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/ram.svg"
            activeColor: "#a6e3a1" // Verde
            suffix: "%"
        }

        ResourceMeter {
            value: root.tempValue
            iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/temperature.svg"
            activeColor: "#f38ba8" // Rojo
            suffix: "°"
        }
    }

    // ── Motor de Monitoreo (JS Puro) ──
    Timer {
        interval: 2000 // Actualiza cada 2 segundos
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // 1. LEER RAM (/proc/meminfo)
            try {
                var reqMem = new XMLHttpRequest();
                reqMem.open("GET", "file:///proc/meminfo", false);
                reqMem.send(null);
                
                var memTotal = 1, memAvail = 0;
                var lines = reqMem.responseText.split('\n');
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].indexOf("MemTotal:") === 0) memTotal = parseInt(lines[i].replace(/[^0-9]/g, ''));
                    if (lines[i].indexOf("MemAvailable:") === 0) memAvail = parseInt(lines[i].replace(/[^0-9]/g, ''));
                }
                root.ramUsage = Math.round(((memTotal - memAvail) / memTotal) * 100);
            } catch(e) { console.log("Error leyendo RAM"); }

            // 2. LEER CPU (/proc/stat)
            try {
                var reqCpu = new XMLHttpRequest();
                reqCpu.open("GET", "file:///proc/stat", false);
                reqCpu.send(null);
                
                var cpuLine = reqCpu.responseText.split('\n')[0];
                var parts = cpuLine.match(/\d+/g);
                if (parts && parts.length >= 4) {
                    var idle = parseInt(parts[3]);
                    var total = 0;
                    for(var j = 0; j < parts.length; j++) total += parseInt(parts[j]);
                    
                    if (root._lastTotal > 0) {
                        var diffIdle = idle - root._lastIdle;
                        var diffTotal = total - root._lastTotal;
                        root.cpuUsage = Math.round((1000 * (diffTotal - diffIdle) / diffTotal + 5) / 10);
                    }
                    root._lastTotal = total;
                    root._lastIdle = idle;
                }
            } catch(e) { console.log("Error leyendo CPU"); }

            // 3. LEER TEMPERATURA (/sys/class/thermal/...)
            try {
                var reqTemp = new XMLHttpRequest();
                // NOTA: 'thermal_zone0' es estándar. Si siempre marca 0, cámbialo por hwmon.
                reqTemp.open("GET", "file:///sys/class/thermal/thermal_zone0/temp", false);
                reqTemp.send(null);
                if (reqTemp.status === 200 || reqTemp.status === 0) {
                    root.tempValue = Math.round(parseInt(reqTemp.responseText) / 1000);
                }
            } catch(e) { console.log("Error leyendo Temperatura"); }
        }
    }
}