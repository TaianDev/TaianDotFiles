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

    property int    selectedIndex:  -1
    property string connectingSsid: ""
    property string errorSsid:      ""

    ListModel { id: wifiModel }

    // ── Scanner ───────────────────────────────────────────────
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
                        saved:    false
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

                // FIX: diff en lugar de clear() — evita el parpadeo
                // 1. Actualizar entradas existentes
                for (let i = 0; i < Math.min(newList.length, wifiModel.count); i++) {
                    const n = newList[i]
                    wifiModel.setProperty(i, "ssid",     n.ssid)
                    wifiModel.setProperty(i, "security", n.security)
                    wifiModel.setProperty(i, "active",   n.active)
                    wifiModel.setProperty(i, "signal",   n.signal)
                    wifiModel.setProperty(i, "saved",    false)
                }
                // 2. Agregar entradas nuevas
                for (let i = wifiModel.count; i < newList.length; i++)
                    wifiModel.append(newList[i])
                // 3. Eliminar entradas sobrantes desde el final
                while (wifiModel.count > newList.length)
                    wifiModel.remove(wifiModel.count - 1)

                // Marcar guardadas
                savedScanner.running = false
                savedScanner.running = true
            }
        }
    }

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

    onVisibleChanged: {
        if (visible) {
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

    Process {
        id: connector
        property string targetSsid: ""
        property string password:   ""

        command: password !== ""
            ? ["nmcli", "dev", "wifi", "connect", targetSsid, "password", password]
            : ["nmcli", "dev", "wifi", "connect", targetSsid]

        onExited: (code) => {
            if (code === 0) {
                root.errorSsid     = ""
                root.selectedIndex = -1
            } else {
                root.errorSsid = root.connectingSsid
            }
            root.connectingSsid = ""
            scanner.running = false
            scanner.running = true
        }
    }

    // ── UI ────────────────────────────────────────────────────
    // FIX: FocusScope para que el foco de teclado pueda llegar al TextField
    FocusScope {
        anchors.fill: parent

        ScrollView {
            anchors.fill: parent
            contentWidth: availableWidth
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            // FIX: ScrollView no debe robar el foco del teclado
            focus: false

            ListView {
                id: listView
                anchors.fill: parent
                model: wifiModel
                spacing: 4
                focus: false

                delegate: Item {
                    id: delegateRoot
                    width:  listView.width
                    height: innerRect.height

                    readonly property bool isConnecting: root.connectingSsid === model.ssid
                    readonly property bool hasError:     root.errorSsid      === model.ssid
                    readonly property bool needsPassword: model.security !== "" && !model.saved
                    readonly property bool isExpanded:   root.selectedIndex === index
                        && !model.active && needsPassword && !isConnecting

                    Rectangle {
                        id: innerRect
                        width:  parent.width
                        radius: 10
                        color: model.active
                            ? Qt.rgba(0.2, 0.6, 1.0, 0.2)
                            : (headerMA.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent")

                        height: isExpanded
                            ? headerRow.height + passRow.height + 8
                            : headerRow.height
                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuart }
                        }

                        // ── Cabecera ──────────────────────────
                        RowLayout {
                            id: headerRow
                            width:  parent.width
                            height: 44
                            anchors.top:         parent.top
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            spacing: 12

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
                                    text: isConnecting ? "Conectando..."
                                        : hasError     ? "Falló la autenticación"
                                        : model.active ? "Conectado"
                                        : model.saved  ? "Guardada"
                                        : ""
                                    color: hasError     ? "#ff3b30"
                                         : model.active ? "#0a84ff"
                                         : Qt.rgba(1,1,1,0.5)
                                    font.pixelSize: 11
                                }
                            }

                            Item {
                                visible: model.security !== "" && !model.active && !isConnecting
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
                        }

                        MouseArea {
                            id: headerMA
                            anchors.top:   parent.top
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            height: headerRow.height
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: 0

                            onClicked: {
                                if (model.active || isConnecting) return
                                root.errorSsid = ""

                                if (!needsPassword) {
                                    root.connectingSsid  = model.ssid
                                    connector.targetSsid = model.ssid
                                    connector.password   = ""
                                    connector.running = false
                                    connector.running = true
                                } else {
                                    root.selectedIndex = (root.selectedIndex === index) ? -1 : index
                                }
                            }
                        }

                        // ── Campo contraseña ──────────────────
                        Item {
                            id: passRow
                            anchors.top:         headerRow.bottom
                            anchors.left:        parent.left
                            anchors.right:       parent.right
                            anchors.leftMargin:  42
                            anchors.rightMargin: 12
                            height: 36
                            visible: isExpanded
                            z: 10  // encima de todo

                            // FIX: Timer para dar foco DESPUÉS de que la animación
                            // de expansión termine y el Item sea visible
                            Timer {
                                id: focusTimer
                                interval: 250
                                repeat: false
                                onTriggered: passField.forceActiveFocus()
                            }

                            onVisibleChanged: {
                                if (visible) {
                                    passField.text = ""
                                    focusTimer.restart()
                                } else {
                                    focusTimer.stop()
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                spacing: 8

                                // FIX: TextField dentro de su propio FocusScope
                                FocusScope {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28

                                    TextField {
                                        id: passField
                                        anchors.fill: parent
                                        placeholderText: "Contraseña..."
                                        placeholderTextColor: Qt.rgba(1,1,1,0.4)
                                        color: "#ffffff"
                                        echoMode: TextInput.Password

                                        background: Rectangle {
                                            radius: 6
                                            color: Qt.rgba(0,0,0,0.4)
                                            border.width: 1
                                            border.color: hasError
                                                ? "#ff3b30"
                                                : (passField.activeFocus
                                                    ? "#0a84ff"
                                                    : Qt.rgba(1,1,1,0.12))
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
                                            connector.running = false
                                            connector.running = true
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth:  56
                                    Layout.preferredHeight: 28
                                    radius: 6
                                    color: "#0a84ff"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Unir"
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.bold: true
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
}
