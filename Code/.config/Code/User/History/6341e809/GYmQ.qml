import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    anchors.fill: parent

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"

    property string connectingSsid: ""
    property string errorSsid:      ""
    property var    savedNetworks:  []

    ListModel { id: wifiModel }

    // ── 1. Escáner Inteligente (Actualización sin parpadeo) ──
    Process {
        id: scanner
        command: [
            "bash", "-c",
            "LC_ALL=C nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n')

                let activeNet = null
                let otherMap  = {}

                for (const line of lines) {
                    if (line === "") continue
                    const idx1     = line.indexOf(':')
                    if (idx1 < 0) continue
                    const inUse    = line.substring(0, idx1)
                    const rest1    = line.substring(idx1 + 1)
                    const signal   = parseInt(rest1.substring(rest1.lastIndexOf(':') + 1))
                    const rest2    = rest1.substring(0, rest1.lastIndexOf(':'))
                    const secIdx   = rest2.lastIndexOf(':')
                    const security = rest2.substring(secIdx + 1)
                    const ssid     = rest2.substring(0, secIdx)

                    if (!ssid || ssid === "") continue

                    const isActive = inUse === "*"
                    const entry = {
                        ssid:     ssid,
                        security: security,
                        active:   isActive,
                        signal:   isNaN(signal) ? 0 : signal,
                        saved:    root.savedNetworks.includes(ssid) // Lee de la caché
                    }

                    if (isActive) {
                        activeNet = entry
                    } else {
                        if (!otherMap[ssid] || otherMap[ssid].signal < entry.signal)
                            otherMap[ssid] = entry
                    }
                }

                const others = Object.values(otherMap).sort((a, b) => b.signal - a.signal)
                const newList = []
                if (activeNet) newList.push(activeNet)
                for (const net of others) newList.push(net)

                // 🌟 FIX: diff inteligente para evitar parpadeos
                for (let i = 0; i < Math.min(newList.length, wifiModel.count); i++) {
                    const n = newList[i]
                    wifiModel.setProperty(i, "ssid",     n.ssid)
                    wifiModel.setProperty(i, "security", n.security)
                    wifiModel.setProperty(i, "active",   n.active)
                    wifiModel.setProperty(i, "signal",   n.signal)
                    wifiModel.setProperty(i, "saved",    n.saved)
                }
                for (let i = wifiModel.count; i < newList.length; i++)
                    wifiModel.append(newList[i])
                while (wifiModel.count > newList.length)
                    wifiModel.remove(wifiModel.count - 1)
            }
        }
    }

    // ── 2. Escáner de Redes Guardadas ──
    Process {
        id: savedScanner
        command: ["bash", "-c", "LC_ALL=C nmcli -t -f NAME connection show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedNetworks = this.text.trim().split('\n').map(l => l.trim())
                // Actualiza el modelo al instante
                for (let i = 0; i < wifiModel.count; i++) {
                    let s = wifiModel.get(i).ssid
                    wifiModel.setProperty(i, "saved", root.savedNetworks.includes(s))
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            savedScanner.running = false
            savedScanner.running = true
            scanner.running = false
            scanner.running = true
        }
    }

    Timer {
        interval: 8000
        running:  root.visible
        repeat:   true
        onTriggered: {
            scanner.running = false
            scanner.running = true
        }
    }

    // ── 3. Acciones de Red (Conectar / Olvidar) ──
    Process {
        id: connector
        property string targetSsid: ""
        // Si pide clave, el OS lanzará la ventana de Polkit automáticamente
        command: ["nmcli", "dev", "wifi", "connect", targetSsid]

        onExited: (code) => {
            if (code === 0) {
                root.errorSsid = ""
            } else {
                root.errorSsid = root.connectingSsid // Falló o el usuario canceló
            }
            root.connectingSsid = ""
            savedScanner.running = false
            savedScanner.running = true
            scanner.running = false
            scanner.running = true
        }
    }

    Process {
        id: forgetter
        property string targetSsid: ""
        command: ["nmcli", "connection", "delete", targetSsid]
        
        onExited: {
            savedScanner.running = false
            savedScanner.running = true
            scanner.running = false
            scanner.running = true
        }
    }

    // ── 4. Interfaz Visual ─────────────────────────────────────
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff

        ListView {
            id: listView
            anchors.fill: parent
            model: wifiModel
            spacing: 4

            delegate: Item {
                width: listView.width
                height: 48 // Altura fija y limpia

                readonly property bool isConnecting:  root.connectingSsid === model.ssid
                readonly property bool hasError:      root.errorSsid      === model.ssid
                readonly property bool needsPassword: model.security !== "" && !model.saved && !model.active

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: model.active 
                        ? Qt.rgba(0.2, 0.6, 1.0, 0.2) 
                        : (bgMa.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")

                    // 🌟 Clic para Conectar
                    MouseArea {
                        id: bgMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.active || isConnecting) return;
                            root.errorSsid = "";
                            root.connectingSsid = model.ssid;
                            connector.targetSsid = model.ssid;
                            connector.running = false;
                            connector.running = true;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Ícono de Señal (Blanco/Azul)
                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Image {
                                id: wifiIcn
                                anchors.fill: parent
                                source: model.signal > 75
                                        ? root.iconsPath + "wifi-full.svg"
                                        : model.signal > 40
                                            ? root.iconsPath + "wifi-medium.svg"
                                            : root.iconsPath + "wifi-low.svg"
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: wifiIcn; source: wifiIcn
                                color: model.active ? "#0a84ff" : "#ffffff"
                            }
                        }

                        // Textos (Nombre y Estado)
                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                text:  model.ssid
                                color: model.active ? "#0a84ff" : "#ffffff"
                                font.pixelSize: 13
                                font.bold: model.active
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                visible: isConnecting || hasError || model.active || model.saved
                                text: isConnecting   ? "Autenticando..."
                                      : hasError     ? "Falló la autenticación"
                                      : model.active ? "Conectado"
                                      : model.saved  ? "Guardada"
                                      : ""
                                color: hasError      ? "#ff3b30"
                                       : model.active? "#0a84ff"
                                       : Qt.rgba(1,1,1,0.5)
                                font.pixelSize: 11
                            }
                        }

                        // Candado (Si requiere clave y no está guardada/activa)
                        Item {
                            visible: needsPassword && !isConnecting
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            Image {
                                id: lockIcn; anchors.fill: parent
                                source: root.iconsPath + "lock.svg"
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcn; source: lockIcn
                                color: Qt.rgba(1,1,1,0.35)
                            }
                        }

                        // 🌟 Botón "Olvidar" (Solo visible en redes guardadas)
                        Rectangle {
                            visible: model.saved && !isConnecting
                            Layout.preferredWidth: 60
                            Layout.preferredHeight: 24
                            radius: 12
                            color: Qt.rgba(1, 0.2, 0.2, 0.15) // Fondo rojo translúcido
                            
                            Text {
                                text: "Olvidar"
                                color: "#ff3b30" // Texto rojo estilo iOS
                                font.pixelSize: 11
                                font.bold: true
                                anchors.centerIn: parent
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    forgetter.targetSsid = model.ssid;
                                    forgetter.running = false;
                                    forgetter.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}