import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    anchors.fill: parent

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"

    property int    selectedIndex:   -1
    property string connectingSsid:  ""
    property string errorSsid:       ""

    ListModel { id: wifiModel }

    // ── Scanner ───────────────────────────────────────────────
    // FIX: usar nmcli con --color=no y LC_ALL=C para evitar problemas de locale
    // FIX: incluir campo BSSID para deduplicar correctamente sin perder la activa
    // FIX: separador | en vez de : para evitar conflictos con SSIDs que contienen ":"
    Process {
        id: scanner
        command: [
            "bash", "-c",
            "LC_ALL=C nmcli -t -f IN-USE,SSID,SECURITY,SIGNAL dev wifi list 2>/dev/null"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                wifiModel.clear()
                const lines = this.text.trim().split('\n')

                let activeNet  = null
                let otherMap   = {}
                let savedNets  = {}

                // Obtener redes guardadas para marcarlas
                // (se hace en paralelo con savedScanner)

                for (const line of lines) {
                    if (line === "") continue
                    // Formato: IN-USE:SSID:SECURITY:SIGNAL
                    // IN-USE es "*" si está activa, "" si no
                    const idx1 = line.indexOf(':')
                    if (idx1 < 0) continue
                    const inUse   = line.substring(0, idx1)          // "*" o ""
                    const rest1   = line.substring(idx1 + 1)
                    const idx2    = rest1.lastIndexOf(':')
                    const idx2b   = rest1.indexOf(':')
                    // SSID puede tener ":" dentro, security y signal no
                    // Format: SSID:SECURITY:SIGNAL — tomamos último ":" para signal
                    const signal  = parseInt(rest1.substring(rest1.lastIndexOf(':') + 1))
                    const rest2   = rest1.substring(0, rest1.lastIndexOf(':'))
                    const secIdx  = rest2.lastIndexOf(':')
                    const security = rest2.substring(secIdx + 1)
                    const ssid     = rest2.substring(0, secIdx)

                    if (!ssid || ssid === "") continue

                    const isActive = inUse === "*"
                    const entry = {
                        ssid:     ssid,
                        security: security,
                        active:   isActive,
                        signal:   isNaN(signal) ? 0 : signal,
                        saved:    false
                    }

                    if (isActive) {
                        activeNet = entry
                    } else {
                        // Guardar solo la entrada con mejor señal por SSID
                        if (!otherMap[ssid] || otherMap[ssid].signal < entry.signal)
                            otherMap[ssid] = entry
                    }
                }

                // La red activa va primero
                if (activeNet) {
                    wifiModel.append(activeNet)
                    delete otherMap[activeNet.ssid]
                }

                // Resto ordenado por señal desc
                const others = Object.values(otherMap).sort((a,b) => b.signal - a.signal)
                for (const net of others)
                    wifiModel.append(net)

                // Marcar redes guardadas en segundo paso
                savedScanner.running = false; savedScanner.running = true
            }
        }
    }

    // Obtiene las redes guardadas en NetworkManager
    Process {
        id: savedScanner
        command: ["bash", "-c", "LC_ALL=C nmcli -t -f NAME connection show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const saved = new Set(this.text.trim().split('\n').map(l => l.trim()))
                for (let i = 0; i < wifiModel.count; i++) {
                    if (saved.has(wifiModel.get(i).ssid))
                        wifiModel.setProperty(i, "saved", true)
                }
            }
        }
    }

    // FIX: scan inicial al hacerse visible + refresh periódico
    onVisibleChanged: if (visible) scanner.running = false; scanner.running = true

    Timer {
        interval: 8000
        running:  root.visible
        repeat:   true
        onTriggered: scanner.running = false; scanner.running = true
    }

    // ── Conector ──────────────────────────────────────────────
    Process {
        id: connector
        property string targetSsid: ""
        property string password:   ""

        // FIX: comando dinámico según si hay contraseña o no
        command: {
            if (password !== "")
                return ["nmcli", "dev", "wifi", "connect", targetSsid, "password", password]
            else
                return ["nmcli", "dev", "wifi", "connect", targetSsid]
        }

        onExited: (code) => {
            if (code === 0) {
                root.errorSsid    = ""
                root.selectedIndex = -1
            } else {
                root.errorSsid = root.connectingSsid
            }
            root.connectingSsid = ""
            // FIX: usar start() para re-ejecutar
            scanner.running = false; scanner.running = true
        }
    }

    // ── UI ────────────────────────────────────────────────────
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
                id: delegateRoot
                width:  listView.width
                // FIX: altura calculada sobre el Item externo, no el Rectangle
                height: innerRect.height

                // Estados
                readonly property bool isConnecting: root.connectingSsid === model.ssid
                readonly property bool hasError:     root.errorSsid      === model.ssid
                // FIX: redes guardadas sin clave también se conectan directo (saved && no password prompt)
                readonly property bool needsPassword: model.security !== "" && !model.saved
                readonly property bool isExpanded: root.selectedIndex === index
                    && !model.active && needsPassword && !isConnecting

                Rectangle {
                    id: innerRect
                    width:  parent.width
                    radius: 10
                    color: model.active
                        ? Qt.rgba(0.2, 0.6, 1.0, 0.2)
                        : (headerMA.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")

                    height: isExpanded ? headerRow.height + passRow.height + 8 : headerRow.height
                    Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                    // ── Cabecera ──────────────────────────────
                    RowLayout {
                        id: headerRow
                        width: parent.width
                        height: 44
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Icono señal
                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Image {
                                id: wifiIcn
                                anchors.fill: parent
                                source: {
                                    if (model.signal > 75) return root.iconsPath + "wifi-full.svg"
                                    if (model.signal > 40) return root.iconsPath + "wifi-medium.svg"
                                    return root.iconsPath + "wifi-low.svg"
                                }
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: wifiIcn; source: wifiIcn
                                color: model.active ? "#0a84ff" : "#ffffff"
                            }
                        }

                        // Nombre + estado
                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                text: model.ssid
                                color: model.active ? "#0a84ff" : "#ffffff"
                                font.pixelSize: 13
                                font.bold: model.active
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                visible: isConnecting || hasError || model.active || model.saved
                                text: {
                                    if (isConnecting) return "Conectando..."
                                    if (hasError)     return "Falló la autenticación"
                                    if (model.active) return "Conectado"
                                    if (model.saved)  return "Guardada"
                                    return ""
                                }
                                color: {
                                    if (hasError)     return "#ff3b30"
                                    if (model.active) return "#0a84ff"
                                    return Qt.rgba(1,1,1,0.5)
                                }
                                font.pixelSize: 11
                            }
                        }

                        // Candado
                        Item {
                            visible: model.security !== "" && !model.active && !isConnecting
                            Layout.preferredWidth: 12; Layout.preferredHeight: 12
                            Image {
                                id: lockIcn; anchors.fill: parent
                                source: root.iconsPath + "lock.svg"; visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcn; source: lockIcn
                                color: Qt.rgba(1,1,1,0.35)
                            }
                        }
                    }

                    // FIX: MouseArea SOLO en la cabecera, z bajo para no tapar TextField
                    MouseArea {
                        id: headerMA
                        anchors.top:    parent.top
                        anchors.left:   parent.left
                        anchors.right:  parent.right
                        height: headerRow.height   // ← solo 44px, no toda la altura
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        z: 0  // TextField tiene z superior implícito

                        onClicked: {
                            if (model.active || isConnecting) return
                            root.errorSsid = ""

                            if (!needsPassword) {
                                // Sin contraseña o ya guardada — conectar directo
                                root.connectingSsid   = model.ssid
                                connector.targetSsid  = model.ssid
                                connector.password    = ""
                                connector.running = false; connector.running = true
                            } else {
                                // Necesita contraseña — expandir/colapsar
                                root.selectedIndex = (root.selectedIndex === index) ? -1 : index
                            }
                        }
                    }

                    // ── Campo contraseña ──────────────────────
                    // FIX: Item separado, debajo del header, z superior
                    Item {
                        id: passRow
                        anchors.top:         headerRow.bottom
                        anchors.left:        parent.left
                        anchors.right:       parent.right
                        anchors.leftMargin:  42
                        anchors.rightMargin: 12
                        height: 36
                        visible: isExpanded
                        // No usar opacity animada — causa que el TextField pierda focus
                        z: 1

                        RowLayout {
                            anchors.fill: parent
                            spacing: 8

                            TextField {
                                id: passField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                placeholderText: "Contraseña..."
                                placeholderTextColor: Qt.rgba(1,1,1,0.4)
                                color: "#ffffff"
                                echoMode: TextInput.Password
                                // FIX: desactivar interceptación de eventos del padre
                                focus: isExpanded

                                background: Rectangle {
                                    radius: 6
                                    color: Qt.rgba(0,0,0,0.4)
                                    border.width: 1
                                    border.color: hasError
                                        ? "#ff3b30"
                                        : (passField.activeFocus ? "#0a84ff" : Qt.rgba(1,1,1,0.12))
                                }

                                // FIX: forceActiveFocus cuando el Item se hace visible
                                onVisibleChanged: {
                                    if (visible) {
                                        text = ""
                                        Qt.callLater(() => forceActiveFocus())
                                    }
                                }

                                Keys.onReturnPressed: doConnect()
                                Keys.onEnterPressed:  doConnect()
                                Keys.onEscapePressed: root.selectedIndex = -1

                                function doConnect() {
                                    if (text.length < 8) {
                                        root.errorSsid = model.ssid
                                        return
                                    }
                                    root.errorSsid       = ""
                                    root.connectingSsid  = model.ssid
                                    connector.targetSsid = model.ssid
                                    connector.password   = text
                                    connector.running = false; connector.running = true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 56
                                Layout.preferredHeight: 28
                                radius: 6
                                color: "#0a84ff"
                                Text {
                                    anchors.centerIn: parent
                                    text: "Unir"
                                    color: "#ffffff"
                                    font.pixelSize: 11; font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: passField.doConnect()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

