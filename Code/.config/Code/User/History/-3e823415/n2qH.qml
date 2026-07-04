import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root
    width: 320
    height: 400 

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"
    signal requestPage(int pageIndex) 

    // ── Variables de Estado ──
    property bool   wifiEnabled: false
    property string wifiNetwork: ""
    property bool   airplaneMode: false
    property bool   dndMode: false
    property bool   nightMode: false
    property real   sysVol: 0
    property real   sysMic: 0
    property real   sysBright: 0

    property var  btAdapter: Bluetooth.defaultAdapter
    property bool btEnabled: btAdapter?.enabled ?? false
    property string btDeviceName: {
        if (!btAdapter || !btAdapter.enabled) return ""
        const devs = btAdapter.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i].name
        }
        return ""
    }

    // ── 1. Súper Escáner de Hardware ──
    Process {
        id: statusScanner
        command: [
            "bash", "-c",
            "WIFI_ON=$(LC_ALL=C nmcli -t -f WIFI radio); " +
            "SSID=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep '802-11-wireless' | cut -d: -f1 | head -n1); " +
            "BLOCKED=$(LC_ALL=C rfkill list wlan bluetooth | grep -i 'soft blocked: yes' | wc -l); " +
            "TOTAL=$(LC_ALL=C rfkill list wlan bluetooth | grep -i 'soft blocked' | wc -l); " +
            "AIRPLANE='false'; if [ \"$TOTAL\" -gt 0 ] && [ \"$BLOCKED\" -eq \"$TOTAL\" ]; then AIRPLANE='true'; fi; " +
            "DND_STATE='false'; if command -v swaync-client >/dev/null; then DND_STATE=$(swaync-client -D); elif command -v dunstctl >/dev/null; then DND_STATE=$(dunstctl is-paused); elif command -v makoctl >/dev/null; then makoctl mode | grep -q 'dnd' && DND_STATE='true'; fi; " +
            "NIGHT_STATE='false'; if pgrep -x hyprsunset > /dev/null; then NIGHT_STATE='true'; fi; " +
            "VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}'); " +
            "MIC=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print int($2 * 100)}'); " +
            "BRIGHT=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'); " +
            "echo \"$WIFI_ON|$SSID|$AIRPLANE|$DND_STATE|$NIGHT_STATE|${VOL:-0}|${MIC:-0}|${BRIGHT:-0}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split('|')
                if (parts.length >= 8) {
                    root.wifiEnabled = (parts[0] === "enabled")
                    root.wifiNetwork = parts[1] 
                    
                    if (!actionRunner.running) {
                        root.airplaneMode = (parts[2] === "true")
                        root.dndMode = (parts[3] === "true")
                        root.nightMode = (parts[4] === "true")
                        // Solo actualiza los sliders si el usuario no los está arrastrando en este momento
                        if (!volSlider.isDragging) root.sysVol = parseInt(parts[5])
                        if (!micSlider.isDragging) root.sysMic = parseInt(parts[6])
                        if (!brightSlider.isDragging) root.sysBright = parseInt(parts[7])
                    }
                }
            }
        }
    }

    Timer { interval: 2000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: { statusScanner.running = false; statusScanner.running = true } }

    // ── 2. Motor Ejecutor de Hardware ──
    Process {
        id: actionRunner
        property string actionType: ""
        property string actionValue: ""
        
        command: {
            if (actionType === "airplane_on")  return ["rfkill", "block", "all"]
            if (actionType === "airplane_off") return ["rfkill", "unblock", "all"]
            if (actionType === "wifi_on")      return ["nmcli", "radio", "wifi", "on"]
            if (actionType === "wifi_off")     return ["nmcli", "radio", "wifi", "off"]
            if (actionType === "dnd_on")       return ["bash", "-c", "if command -v swaync-client >/dev/null; then swaync-client -d; elif command -v dunstctl >/dev/null; then dunstctl set-paused true; fi"]
            if (actionType === "dnd_off")      return ["bash", "-c", "if command -v swaync-client >/dev/null; then swaync-client -d; elif command -v dunstctl >/dev/null; then dunstctl set-paused false; fi"]
            // 🌟 Comandos Hyprsunset y Sliders
            if (actionType === "night_on")     return ["bash", "-c", "hyprsunset -t 4000 &"] // Se lanza en segundo plano
            if (actionType === "night_off")    return ["killall", "hyprsunset"]
            if (actionType === "vol")          return ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (parseInt(actionValue)/100)]
            if (actionType === "mic")          return ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (parseInt(actionValue)/100)]
            if (actionType === "bright")       return ["brightnessctl", "set", actionValue + "%"]
            
            return ["true"]
        }
        onExited: { statusScanner.running = false; statusScanner.running = true }
    }

    // ── 3. Interfaz Visual ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Fila 1: Botones Cuadrados Principales
        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            NetworkToggle {
                title: "Wi-Fi"
                subtitle: root.wifiEnabled ? (root.wifiNetwork !== "" ? root.wifiNetwork : "Encendido") : "Apagado"
                isToggled: root.wifiEnabled
                iconSource: root.wifiEnabled ? root.iconsPath + "wifi-full.svg" : root.iconsPath + "no-wifi.svg"
                iconTint: root.wifiEnabled ? "#0a84ff" : "#ffffff" 
                
                onToggleClicked: {
                    root.wifiEnabled = !root.wifiEnabled
                    if (root.wifiEnabled) root.airplaneMode = false
                    actionRunner.actionType = root.wifiEnabled ? "wifi_on" : "wifi_off"
                    actionRunner.running = false; actionRunner.running = true
                }
                onArrowClicked: root.requestPage(1) 
            }

            NetworkToggle {
                title: "Bluetooth"
                subtitle: root.btEnabled ? (root.btDeviceName !== "" ? root.btDeviceName : "Encendido") : "Apagado"
                isToggled: root.btEnabled
                iconSource: root.btEnabled ? root.iconsPath + "bluetooth.svg" : root.iconsPath + "no-bluetooth.svg"
                iconTint: root.btEnabled ? "#0a84ff" : "#ffffff"
                
                onToggleClicked: {
                    if (root.btAdapter) {
                        root.btAdapter.enabled = !root.btAdapter.enabled
                        if (root.btAdapter.enabled) root.airplaneMode = false
                    }
                }
                onArrowClicked: root.requestPage(2) 
            }
        }

        // Fila 2: Interruptores Pequeños (Grid de 2 columnas)
        GridLayout {
            columns: 2
            columnSpacing: 12
            rowSpacing: 12
            Layout.alignment: Qt.AlignHCenter

            SmallToggle {
                iconText: "✈"
                title: "Avión"
                isToggled: root.airplaneMode
                activeColor: "#ff9f0a" // Naranja
                onClicked: {
                    root.airplaneMode = !root.airplaneMode
                    if (root.airplaneMode) { root.wifiEnabled = false; if (root.btAdapter) root.btAdapter.enabled = false; }
                    actionRunner.actionType = root.airplaneMode ? "airplane_on" : "airplane_off"
                    actionRunner.running = false; actionRunner.running = true
                }
            }

            SmallToggle {
                iconText: "🌙"
                title: "Silencio"
                isToggled: root.dndMode
                activeColor: "#5e5ce6" // Morado iOS
                onClicked: {
                    root.dndMode = !root.dndMode
                    actionRunner.actionType = root.dndMode ? "dnd_on" : "dnd_off"
                    actionRunner.running = false; actionRunner.running = true
                }
            }

            SmallToggle {
                iconText: "🌗"
                title: "Noche"
                isToggled: root.nightMode
                activeColor: "#ff9f0a" // Naranja cálido
                // Ocupa dos espacios (toda la fila) para mantener la cuadrícula
                Layout.columnSpan: 2
                Layout.fillWidth: true
                
                onClicked: {
                    root.nightMode = !root.nightMode
                    actionRunner.actionType = root.nightMode ? "night_on" : "night_off"
                    actionRunner.running = false; actionRunner.running = true
                }
            }
        }

        // Fila 3: Sliders de Sistema
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 12

            CustomSlider {
                id: brightSlider
                iconSource: root.iconsPath + "brightness.svg" // *Asegúrate de tener este ícono
                activeColor: "#ffffff"
                value: root.sysBright
                onMoved: (val) => {
                    actionRunner.actionType = "bright"
                    actionRunner.actionValue = val.toString()
                    actionRunner.running = false; actionRunner.running = true
                }
            }

            CustomSlider {
                id: volSlider
                iconSource: root.iconsPath + "volume.svg" // *Asegúrate de tener este ícono
                activeColor: "#0a84ff"
                value: root.sysVol
                onMoved: (val) => {
                    actionRunner.actionType = "vol"
                    actionRunner.actionValue = val.toString()
                    actionRunner.running = false; actionRunner.running = true
                }
            }

            CustomSlider {
                id: micSlider
                iconSource: root.iconsPath + "mic.svg" // *Asegúrate de tener este ícono
                activeColor: "#ff3b30" // Rojo advertencia
                value: root.sysMic
                onMoved: (val) => {
                    actionRunner.actionType = "mic"
                    actionRunner.actionValue = val.toString()
                    actionRunner.running = false; actionRunner.running = true
                }
            }
        }
    }
}