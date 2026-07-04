








import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io // 🌟 Módulo de Input/Output nativo de Quickshell

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

    // 🌟 MOTOR DE LECTURA ASÍNCRONA
    Process {
        id: sysMon
        // Apunta directamente a tu usuario y script
        command: ["bash", "/home/taianlux/.config/quickshell/scripts/sysmon.sh"]
        running: true
        
        // Cada vez que el script hace "echo", esta función atrapa los números
        onStdout: function(output) {
            var parts = output.trim().split(",");
            if (parts.length === 3) {
                root.cpuUsage = parseInt(parts[0]);
                root.ramUsage = parseInt(parts[1]);
                root.tempValue = parseInt(parts[2]);
            }
        }
    }

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
}