import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root
    width: 320
    height: 140

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"
    signal requestPage(int pageIndex) 

    // ── Variables de Estado ──
    property bool   wifiEnabled: false
    property string wifiNetwork: "Desconectado"
    property bool   airplaneMode: false

    property var  btAdapter: Bluetooth.defaultAdapter
    property bool btEnabled: btAdapter?.enabled ?? false
    property string btDeviceName: {
        if (!btAdapter) return "Desconectado"
        const devs = btAdapter.devices.values
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i].name
        }
        return "Desconectado"
    }

    // ── 1. Escáner de Estado (Wi-Fi y Modo Avión) ──
    Process {
        id: statusScanner
        command: [
            "bash", "-c",
            // Verifica si el Wi-Fi está encendido, extrae la red conectada, y revisa si rfkill bloqueó las antenas
            "WIFI_ON=$(nmcli -t -f WIFI radio); " +
            "SSID=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -n1); " +
            "BLOCKED=$(rfkill list wlan bluetooth | grep 'Soft blocked: yes' | wc -l); " +
            "TOTAL=$(rfkill list wlan bluetooth | grep 'Soft blocked' | wc -l); " +
            "AIRPLANE='false'; " +
            "if [ \"$TOTAL\" -gt 0 ] && [ \"$BLOCKED\" -eq \"$TOTAL\" ]; then AIRPLANE='true'; fi; " +
            "echo \"$WIFI_ON|$SSID|$AIRPLANE\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split('|')
                if (parts.length >= 3) {
                    root.wifiEnabled = (parts[0] === "enabled")
                    root.wifiNetwork = parts[1] !== "" ? parts[1] : "Desconectado"
                    
                    // Solo actualizamos si no estamos ejecutando una acción para evitar saltos visuales
                    if (!actionRunner.running) {
                        root.airplaneMode = (parts[2] === "true")
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
            return ["true"]
        }
        
        onExited: {
            // Tras ejecutar, forzamos la lectura para actualizar la interfaz
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

            // 🌟 Interruptor Wi-Fi Real
            NetworkToggle {
                title: "Wi-Fi"
                subtitle: root.wifiEnabled ? root.wifiNetwork : "Apagado"
                isToggled: root.wifiEnabled
                iconSource: root.wifiEnabled ? root.iconsPath + "wifi-full.svg" : root.iconsPath + "no-wifi.svg"
                iconTint: root.wifiEnabled ? "#0a84ff" : "#ffffff" 
                
                onToggleClicked: {
                    root.wifiEnabled = !root.wifiEnabled
                    if (root.wifiEnabled) root.airplaneMode = false // Apaga el modo avión visualmente
                    
                    actionRunner.actionType = root.wifiEnabled ? "wifi_on" : "wifi_off"
                    actionRunner.running = false
                    actionRunner.running = true
                }
                onArrowClicked: root.requestPage(1) 
            }

            // 🌟 Interruptor Bluetooth Real
            NetworkToggle {
                title: "Bluetooth"
                subtitle: root.btEnabled ? root.btDeviceName : "Apagado"
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

        // 🌟 Interruptor Modo Avión Real
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
                            
                            // Lógica iOS: Si activo el modo avión, apago los botones de arriba
                            if (root.airplaneMode) {
                                root.wifiEnabled = false
                                if (root.btAdapter) root.btAdapter.enabled = false
                            }
                            
                            // Dispara el comando al sistema (rfkill)
                            actionRunner.actionType = root.airplaneMode ? "airplane_on" : "airplane_off"
                            actionRunner.running = false
                            actionRunner.running = true
                        }
                    }
                }
            }
        }
    }
}