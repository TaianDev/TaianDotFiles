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
    
    // 🌟 Variables de Estado para la Autenticación
    property int    selectedIndex: -1 
    property string connectingSsid: ""
    property string errorSsid: ""

    ListModel { id: wifiModel }

    // ── 1. Escáner de Redes ──
    Process {
        id: scanner
        command: ["bash", "-c", "nmcli -t -f SSID,SECURITY,ACTIVE,SIGNAL dev wifi | grep -v '^:' | sort -u -t: -k1,1"]
        running: root.visible
        stdout: StdioCollector {
            onStreamFinished: {
                wifiModel.clear()
                const lines = this.text.trim().split('\n')
                
                let activeNet = null
                let otherMap = {}

                for (let line of lines) {
                    if (line === "") continue
                    const parts = line.split(':')
                    if (parts.length >= 4 && parts[0] !== "") {
                        let ssid = parts[0]
                        let security = parts[1]
                        let isActive = (parts[2] === "yes" || parts[2] === "sí" || parts[2] === "true")
                        let signal = parseInt(parts[3])

                        if (isActive) {
                            activeNet = { ssid: ssid, security: security, active: true, signal: signal }
                        } else {
                            if (!otherMap[ssid] || otherMap[ssid].signal < signal) {
                                otherMap[ssid] = { ssid: ssid, security: security, active: false, signal: signal }
                            }
                        }
                    }
                }

                if (activeNet) {
                    wifiModel.append(activeNet)
                    delete otherMap[activeNet.ssid] 
                }

                for (let key in otherMap) {
                    wifiModel.append(otherMap[key])
                }
            }
        }
    }

    Timer {
        interval: 8000; running: root.visible; repeat: true
        onTriggered: scanner.running = true 
    }

    // ── 2. Conector de Redes ──
    Process {
        id: connector
        property string targetSsid: ""
        property string password: ""
        
        command: password === "" 
                 ? ["nmcli", "dev", "wifi", "connect", targetSsid]
                 : ["nmcli", "dev", "wifi", "connect", targetSsid, "password", password]
                 
        onExited: (code) => {
            scanner.running = true 
            if (code !== 0) {
                // Si falla, guardamos el error para mostrarlo en rojo
                root.errorSsid = root.connectingSsid
            } else {
                // Si funciona, limpiamos todo y cerramos la caja
                root.errorSsid = ""
                root.selectedIndex = -1 
            }
            // Terminó la carga, quitamos el estado "Autenticando..."
            root.connectingSsid = ""
        }
    }

    // ── 3. Interfaz Visual ──
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

            delegate: Rectangle {
                width: listView.width
                radius: 10
                color: model.active ? Qt.rgba(0.2, 0.6, 1.0, 0.2) : (ma.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent")
                
                // Estados Lógicos del bloque
                property bool isConnecting: root.connectingSsid === model.ssid
                property bool hasError: root.errorSsid === model.ssid
                // Se expande solo si está seleccionado, no es la red activa, tiene clave y NO está autenticando
                property bool isExpanded: root.selectedIndex === index && !model.active && model.security !== "" && !isConnecting
                
                height: isExpanded ? 80 : 44
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                // 🌟 CABECERA DE LA RED (Solo 44px de alto)
                Item {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 44

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Ícono de Señal
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
                                anchors.fill: wifiIcn
                                source: wifiIcn
                                color: model.active ? "#0a84ff" : "#ffffff"
                            }
                        }

                        // Columna con Nombre y Subtítulo de Estado
                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            
                            Text {
                                text: model.ssid
                                color: model.active ? "#0a84ff" : "#ffffff"
                                font.pixelSize: 13
                                font.bold: model.active
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            // 🌟 Mensajes de Estado (iOS style)
                            Text {
                                visible: isConnecting || hasError
                                text: isConnecting ? "Autenticando..." : "Falló la autenticación"
                                color: hasError ? "#ff3b30" : Qt.rgba(1, 1, 1, 0.6)
                                font.pixelSize: 11
                            }
                        }

                        // Ícono de Candado
                        Item {
                            visible: model.security !== "" && !model.active && !isConnecting
                            Layout.preferredWidth: 12
                            Layout.preferredHeight: 12
                            Image {
                                id: lockIcn
                                anchors.fill: parent
                                source: root.iconsPath + "lock.svg"
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: lockIcn
                                source: lockIcn
                                color: Qt.rgba(1, 1, 1, 0.4) 
                            }
                        }
                    }

                    // 🌟 MOUSE AREA RESTRINGIDO: Ya no bloquea la contraseña
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (model.active || isConnecting) return; 
                            
                            root.errorSsid = ""; // Limpia el error al volver a intentar
                            
                            if (model.security === "") {
                                root.connectingSsid = model.ssid;
                                connector.targetSsid = model.ssid;
                                connector.password = "";
                                connector.running = true;
                            } else {
                                root.selectedIndex = root.selectedIndex === index ? -1 : index;
                            }
                        }
                    }
                }

                // ── Campo Desplegable de Contraseña ──
                Item {
                    anchors.top: parent.top
                    anchors.topMargin: 44
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    visible: isExpanded
                    opacity: isExpanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 42
                        anchors.rightMargin: 12
                        spacing: 8

                        TextField {
                            id: passField
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            placeholderText: "Contraseña..."
                            placeholderTextColor: Qt.rgba(1,1,1,0.4)
                            color: "#ffffff"
                            echoMode: TextInput.Password
                            
                            background: Rectangle {
                                radius: 6
                                color: Qt.rgba(0,0,0,0.4)
                                border.width: 1
                                // Si hay error, el borde se vuelve rojo
                                border.color: hasError ? "#ff3b30" : (passField.activeFocus ? "#0a84ff" : Qt.rgba(1,1,1,0.1))
                            }
                            
                            // 🌟 Auto-Enfoque Mágico
                            onVisibleChanged: {
                                if (visible) {
                                    passField.forceActiveFocus()
                                    passField.text = "" 
                                }
                            }
                            
                            onAccepted: {
                                root.errorSsid = "";
                                root.connectingSsid = model.ssid;
                                connector.targetSsid = model.ssid;
                                connector.password = text;
                                connector.running = true;
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 60
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
                                onClicked: {
                                    root.errorSsid = "";
                                    root.connectingSsid = model.ssid;
                                    connector.targetSsid = model.ssid;
                                    connector.password = passField.text;
                                    connector.running = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}