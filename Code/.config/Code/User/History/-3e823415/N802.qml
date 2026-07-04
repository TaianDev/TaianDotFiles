import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root
    width: 320
    height: 196 // 🌟 Aumentamos la altura para hacerle espacio al nuevo botón

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"
    signal requestPage(int pageIndex) 

    // ── Variables de Estado ──
    property bool   wifiEnabled: false
    property string wifiNetwork: ""
    property bool   airplaneMode: false
    property bool   dndMode: false // 🌟 Estado de No Molestar

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

    // ── 1. Escáner de Estado (Wi-Fi, Avión y No Molestar) ──
    Process {
        id: statusScanner
        command: [
            "bash", "-c",
            "WIFI_ON=$(LC_ALL=C nmcli -t -f WIFI radio); " +
            "SSID=$(LC_ALL=C nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep '802-11-wireless' | cut -d: -f1 | head -n1); " +
            "BLOCKED=$(LC_ALL=C rfkill list wlan bluetooth | grep -i 'soft blocked: yes' | wc -l); " +
            "TOTAL=$(LC_ALL=C rfkill list wlan bluetooth | grep -i 'soft blocked' | wc -l); " +
            "AIRPLANE='false'; " +
            "if [ \"$TOTAL\" -gt 0 ] && [ \"$BLOCKED\" -eq \"$TOTAL\" ]; then AIRPLANE='true'; fi; " +
            // 🌟 Detección Universal de Notificaciones (SwayNC, Dunst o Mako)
            "DND_STATE='false'; " +
            "if command -v swaync-client >/dev/null; then DND_STATE=$(swaync-client -D); " +
            "elif command -v dunstctl >/dev/null; then DND_STATE=$(dunstctl is-paused); " +
            "elif command -v makoctl >/dev/null; then makoctl mode | grep -q 'dnd' && DND_STATE='true'; fi; " +
            "echo \"$WIFI_ON|$SSID|$AIRPLANE|$DND_STATE\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split('|')
                if (parts.length >= 4) {
                    root.wifiEnabled = (parts[0] === "enabled")
                    root.wifiNetwork = parts[1] 
                    
                    if (!actionRunner.running) {
                        root.airplaneMode = (parts[2] === "true")
                        root.dndMode = (parts[3] === "true") // Sincroniza visualmente
                    }
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusScanner.running = false
            statusScanner.running = true
        }
    }

    // ── 2. Motor Ejecutor de Acciones ──
    Process {
        id: actionRunner
        property string actionType: ""
        
        command: {
            if (actionType === "airplane_on")  return ["rfkill", "block", "all"]
            if (actionType === "airplane_off") return ["rfkill", "unblock", "all"]
            if (actionType === "wifi_on")      return ["nmcli", "radio", "wifi", "on"]
            if (actionType === "wifi_off")     return ["nmcli", "radio", "wifi", "off"]
            // 🌟 Lógica de encendido y apagado de DND
            if (actionType === "dnd_on")       return ["bash", "-c", "if command -v swaync-client >/dev/null; then [ \"$(swaync-client -D)\" = \"false\" ] && swaync-client -d; elif command -v dunstctl >/dev/null; then dunstctl set-paused true; elif command -v makoctl >/dev/null; then makoctl mode -a dnd; fi"]
            if (actionType === "dnd_off")      return ["bash", "-c", "if command -v swaync-client >/dev/null; then [ \"$(swaync-client -D)\" = \"true\" ] && swaync-client -d; elif command -v dunstctl >/dev/null; then dunstctl set-paused false; elif command -v makoctl >/dev/null; then makoctl mode -r dnd; fi"]
            return ["true"]
        }
        
        onExited: {
            statusScanner.running = false
            statusScanner.running = true
        }
    }

    // ── 3. Interfaz Visual ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 12

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

        // Interruptor Modo Avión
        Rectangle {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 44
            radius: 12
            color: Qt.rgba(0.2, 0.2, 0.2, 0.8)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                Text { text: "✈"; color: root.airplaneMode ? "#ff9f0a" : "#ffffff"; font.pixelSize: 16 }
                Text { text: "Modo Avión"; color: "#ffffff"; font.pixelSize: 14; Layout.fillWidth: true }
                
                Rectangle {
                    width: 36; height: 20; radius: 10
                    color: root.airplaneMode ? "#ff9f0a" : Qt.rgba(1, 1, 1, 0.2)
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        color: "#ffffff"
                        y: 2; x: root.airplaneMode ? 18 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.airplaneMode = !root.airplaneMode
                            if (root.airplaneMode) {
                                root.wifiEnabled = false
                                if (root.btAdapter) root.btAdapter.enabled = false
                            }
                            actionRunner.actionType = root.airplaneMode ? "airplane_on" : "airplane_off"
                            actionRunner.running = false; actionRunner.running = true
                        }
                    }
                }
            }
        }

        // 🌟 NUEVO: Interruptor No Molestar
        Rectangle {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 44
            radius: 12
            color: Qt.rgba(0.2, 0.2, 0.2, 0.8)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10
                
                Text { text: "🌙"; color: root.dndMode ? "#5e5ce6" : "#ffffff"; font.pixelSize: 16 }
                Text { text: "No Molestar"; color: "#ffffff"; font.pixelSize: 14; Layout.fillWidth: true }
                
                Rectangle {
                    width: 36; height: 20; radius: 10
                    // Morado/Púrpura estilo iOS para el DND
                    color: root.dndMode ? "#5e5ce6" : Qt.rgba(1, 1, 1, 0.2)
                    Rectangle {
                        width: 16; height: 16; radius: 8
                        color: "#ffffff"
                        y: 2; x: root.dndMode ? 18 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.dndMode = !root.dndMode
                            actionRunner.actionType = root.dndMode ? "dnd_on" : "dnd_off"
                            actionRunner.running = false
                            actionRunner.running = true
                        }
                    }
                }
            }
        }
    }
}