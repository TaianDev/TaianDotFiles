import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root
    width: 320
    height: 386 // 🌟 Altura encogida para eliminar el espacio muerto

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"
    signal requestPage(int pageIndex) 

    // ── Variables de Estado ──
    property bool   wifiEnabled: false
    property string wifiNetwork: ""
    property bool   airplaneMode: false
    property bool   dndMode: false
    property bool   nightMode: false
    
    // Sliders
    property real   sysVol: 0
    property bool   sysVolMute: false
    property real   sysMic: 0
    property bool   sysMicMute: false
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

    // ── 1. Súper Escáner ──
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
            "VS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); VOL=$(echo \"$VS\" | awk '{print int($2 * 100)}'); VM=$(echo \"$VS\" | grep -q 'MUTED' && echo 'true' || echo 'false'); " +
            "MS=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null); MIC=$(echo \"$MS\" | awk '{print int($2 * 100)}'); MM=$(echo \"$MS\" | grep -q 'MUTED' && echo 'true' || echo 'false'); " +
            "BRIGHT=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'); " +
            "echo \"$WIFI_ON|$SSID|$AIRPLANE|$DND_STATE|$NIGHT_STATE|${VOL:-0}|$VM|${MIC:-0}|$MM|${BRIGHT:-0}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split('|')
                if (parts.length >= 10) {
                    root.wifiEnabled = (parts[0] === "enabled")
                    root.wifiNetwork = parts[1] 
                    
                    if (!actionRunner.running) {
                        root.airplaneMode = (parts[2] === "true")
                        root.dndMode = (parts[3] === "true")
                        root.nightMode = (parts[4] === "true")
                        
                        if (!volSlider.isDragging) root.sysVol = parseInt(parts[5])
                        root.sysVolMute = (parts[6] === "true")
                        
                        if (!micSlider.isDragging) root.sysMic = parseInt(parts[7])
                        root.sysMicMute = (parts[8] === "true")
                        
                        if (!brightSlider.isDragging) root.sysBright = parseInt(parts[9])
                    }
                }
            }
        }
    }

    Timer { interval: 2000; running: root.visible; repeat: true; triggeredOnStart: true; onTriggered: { statusScanner.running = false; statusScanner.running = true } }

    // ── 2. Motor Ejecutor ──
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
            if (actionType === "night_on")     return ["bash", "-c", "hyprsunset -t 4000 &"]
            if (actionType === "night_off")    return ["killall", "hyprsunset"]
            
            if (actionType === "vol")          return ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (parseInt(actionValue)/100)]
            if (actionType === "mic")          return ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + (parseInt(actionValue)/100)]
            if (actionType === "bright")       return ["brightnessctl", "set", actionValue + "%"]
            if (actionType === "mute_vol")     return ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
            if (actionType === "mute_mic")     return ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
            
            if (actionType === "lock")         return ["hyprlock"]
            if (actionType === "sleep")        return ["systemctl", "suspend"]
            if (actionType === "logout")       return ["hyprctl", "dispatch", "exit"]
            if (actionType === "poweroff")     return ["systemctl", "poweroff"]
            
            return ["true"]
        }
        onExited: { statusScanner.running = false; statusScanner.running = true }
    }

    // ── 3. Interfaz Visual ──
    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // 1. Redes
        RowLayout {
            spacing: 12; Layout.alignment: Qt.AlignHCenter
            NetworkToggle {
                title: "Wi-Fi"; subtitle: root.wifiEnabled ? (root.wifiNetwork !== "" ? root.wifiNetwork : "Encendido") : "Apagado"
                isToggled: root.wifiEnabled; iconSource: root.wifiEnabled ? root.iconsPath + "wifi-full.svg" : root.iconsPath + "no-wifi.svg"
                iconTint: root.wifiEnabled ? "#0a84ff" : "#ffffff" 
                onToggleClicked: { root.wifiEnabled = !root.wifiEnabled; if (root.wifiEnabled) root.airplaneMode = false; actionRunner.actionType = root.wifiEnabled ? "wifi_on" : "wifi_off"; actionRunner.running = false; actionRunner.running = true }
                onArrowClicked: root.requestPage(1) 
            }
            NetworkToggle {
                title: "Bluetooth"; subtitle: root.btEnabled ? (root.btDeviceName !== "" ? root.btDeviceName : "Encendido") : "Apagado"
                isToggled: root.btEnabled; iconSource: root.btEnabled ? root.iconsPath + "bluetooth.svg" : root.iconsPath + "no-bluetooth.svg"
                iconTint: root.btEnabled ? "#0a84ff" : "#ffffff"
                onToggleClicked: { if (root.btAdapter) { root.btAdapter.enabled = !root.btAdapter.enabled; if (root.btAdapter.enabled) root.airplaneMode = false } }
                onArrowClicked: root.requestPage(2) 
            }
        }

        // 2. Modos
        GridLayout {
            columns: 2; columnSpacing: 12; rowSpacing: 12; Layout.alignment: Qt.AlignHCenter
            SmallToggle {
                iconText: "✈"; title: "Avión"; isToggled: root.airplaneMode; activeColor: "#ff9f0a"
                onClicked: { root.airplaneMode = !root.airplaneMode; if (root.airplaneMode) { root.wifiEnabled = false; if (root.btAdapter) root.btAdapter.enabled = false; } actionRunner.actionType = root.airplaneMode ? "airplane_on" : "airplane_off"; actionRunner.running = false; actionRunner.running = true }
            }
            SmallToggle {
                iconText: "🌙"; title: "Silencio"; isToggled: root.dndMode; activeColor: "#5e5ce6"
                onClicked: { root.dndMode = !root.dndMode; actionRunner.actionType = root.dndMode ? "dnd_on" : "dnd_off"; actionRunner.running = false; actionRunner.running = true }
            }
            SmallToggle {
                iconText: "🌗"; title: "Noche"; isToggled: root.nightMode; activeColor: "#ff9f0a"
                Layout.columnSpan: 2; Layout.fillWidth: true
                onClicked: { root.nightMode = !root.nightMode; actionRunner.actionType = root.nightMode ? "night_on" : "night_off"; actionRunner.running = false; actionRunner.running = true }
            }
        }

        // 3. Sliders de Sistema
        ColumnLayout {
            Layout.fillWidth: true; Layout.topMargin: 4; Layout.rightMargin: 6; spacing: 14
            
            CustomSlider {
                id: brightSlider; value: root.sysBright
                iconSource: root.iconsPath + "brightness.svg"; activeColor: "#ffffff"
                onMoved: (val) => { actionRunner.actionType = "bright"; actionRunner.actionValue = val.toString(); actionRunner.running = false; actionRunner.running = true }
            }

            CustomSlider {
                id: volSlider; value: root.sysVol
                iconSource: root.iconsPath + "volume.svg"; activeColor: "#0a84ff"
                canMute: true; isMuted: root.sysVolMute; mutedIconSource: root.iconsPath + "no-volume.svg"
                onMoved: (val) => { actionRunner.actionType = "vol"; actionRunner.actionValue = val.toString(); actionRunner.running = false; actionRunner.running = true }
                onToggleMuteClicked: { actionRunner.actionType = "mute_vol"; actionRunner.running = false; actionRunner.running = true }
            }

            CustomSlider {
                id: micSlider; value: root.sysMic
                iconSource: root.iconsPath + "mic.svg"; activeColor: "#ff3b30"
                canMute: true; isMuted: root.sysMicMute; mutedIconSource: root.iconsPath + "no-mic.svg"
                onMoved: (val) => { actionRunner.actionType = "mic"; actionRunner.actionValue = val.toString(); actionRunner.running = false; actionRunner.running = true }
                onToggleMuteClicked: { actionRunner.actionType = "mute_mic"; actionRunner.running = false; actionRunner.running = true }
            }
        }

        // 🌟 4. Botones de Energía (Sin el espaciador anterior, usando topMargin)
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10 // Mantiene una distancia prudente de los sliders
            spacing: 18

            ListModel {
                id: powerModel
                ListElement { icon: "lock"; action: "lock"; col: "#0a84ff" }
                ListElement { icon: "sleep"; action: "sleep"; col: "#ff9f0a" }
                ListElement { icon: "logout"; action: "logout"; col: "#5e5ce6" }
                ListElement { icon: "power"; action: "poweroff"; col: "#ff3b30" }
            }

            Repeater {
                model: powerModel
                Rectangle {
                    width: 44; height: 44; radius: 22 
                    color: pwrMa.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        id: pwrIcn
                        anchors.centerIn: parent
                        source: root.iconsPath + model.icon + ".svg"
                        width: 20; height: 20; sourceSize: Qt.size(20,20)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: pwrIcn; source: pwrIcn
                        color: pwrMa.containsMouse ? model.col : Qt.rgba(1,1,1,0.8)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    MouseArea {
                        id: pwrMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionRunner.actionType = model.action
                            actionRunner.running = false; actionRunner.running = true
                        }
                    }
                }
            }
        }
    }
}