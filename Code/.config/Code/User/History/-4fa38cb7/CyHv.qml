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
    clip: true

    property int cpuUsage: 0
    property int ramUsage: 0
    property int tempValue: 0

    // 1. Mantiene el script de Bash ejecutándose silenciosamente de fondo
    Process {
        id: sysMonProcess
        command: ["bash", "/home/taianlux/.config/quickshell/scripts/sysmon.sh"]
        running: true
    }

    // 2. Lee el archivo real generado por el script cada 2 segundos
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            try {
                var req = new XMLHttpRequest();
                // El timestamp evita que QML lea el archivo viejo de la caché
                req.open("GET", "file:///tmp/quickshell_sysmon.out?" + new Date().getTime(), false);
                req.send(null);
                
                if (req.status === 200 || req.status === 0) {
                    var parts = req.responseText.trim().split(",");
                    if (parts.length === 3) {
                        root.cpuUsage = parseInt(parts[0]);
                        root.ramUsage = parseInt(parts[1]);
                        root.tempValue = parseInt(parts[2]);
                    }
                }
            } catch(e) { }
        }
    }

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
}