import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic // Necesario para el TextField (Caja de texto)
import Quickshell
import Quickshell.Io

Item {
    id: root
    anchors.fill: parent

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"
    property int selectedIndex: -1 // Guarda qué red hemos tocado para poner clave

    ListModel { id: wifiModel }

    // ── 1. Escáner de Redes (Usa NetworkManager nativo) ──
    Process {
        id: scanner
        // Extrae SSID, Seguridad, Si está en uso, y Señal. (sort -u elimina duplicados)
        command: ["bash", "-c", "nmcli -t -f SSID,SECURITY,ACTIVE,SIGNAL dev wifi | grep -v '^:' | sort -u -t: -k1,1"]
        running: root.visible
        stdout: StdioCollector {
            onStreamFinished: {
                wifiModel.clear()
                const outputText = this.text
                const lines = outputText.trim().split('\n')
                for (let line of lines) {
                    if (line === "") continue
                    const parts = line.split(':')
                    if (parts.length >= 4 && parts[0] !== "") {
                        wifiModel.append({
                            ssid: parts[0],
                            security: parts[1],
                            active: parts[2] === "yes" || parts[2] === "sí",
                            signal: parseInt(parts[3])
                        })
                    }
                }
            }
        }
    }

    // Refresca la lista cada 8 segundos si la ventana está abierta
    Timer {
        interval: 8000; running: root.visible; repeat: true
        onTriggered: scanner.running = true 
    }

    // ── 2. Conector de Redes ──
    Process {
        id: connector
        property string targetSsid: ""
        property string password: ""
        
        // Si no hay clave, intenta conectar directo. Si hay clave, la envía.
        command: password === "" 
                 ? ["nmcli", "dev", "wifi", "connect", targetSsid]
                 : ["nmcli", "dev", "wifi", "connect", targetSsid, "password", password]
                 
        onExited: (code) => {
            scanner.running = true // Vuelve a escanear tras intentar conectar
            root.selectedIndex = -1 // Cierra el menú desplegable
        }
    }

    // ── 3. Interfaz de Lista (Estilo iOS) ──
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ListView {
            id: listView
            anchors.fill: parent
            model: wifiModel
            spacing: 4

            delegate: Rectangle {
                width: listView.width
                // Se expande a 80px si lo tocamos y necesita clave, sino 44px
                height: isExpanded ? 80 : 44
                radius: 10
                color: model.active ? Qt.rgba(0.2, 0.6, 1.0, 0.2) : (ma.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent")
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                property bool isExpanded: root.selectedIndex === index && !model.active && model.security !== ""

                // Fila principal (Info de la red)
                RowLayout {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 44
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Icono de Señal WiFi Dinámico
                    Image {
                        Layout.preferredWidth: 18; Layout.preferredHeight: 18
                        source: {
                            if (model.signal > 75) return root.iconsPath + "wifi-full.svg"
                            if (model.signal > 40) return root.iconsPath + "wifi-medium.svg"
                            return root.iconsPath + "wifi-low.svg"
                        }
                    }

                    // Nombre de la red
                    Text {
                        Layout.fillWidth: true
                        text: model.ssid
                        color: model.active ? "#0a84ff" : "#ffffff"
                        font.pixelSize: 13
                        font.bold: model.active
                        elide: Text.ElideRight
                    }

                    // Candado (Si tiene contraseña)
                    Text {
                        visible: model.security !== ""
                        text: "🔒"
                        color: Qt.rgba(1,1,1,0.4)
                        font.pixelSize: 11
                    }

                    // Check (Si está conectado)
                    Text {
                        visible: model.active
                        text: "✓"
                        color: "#34c759"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }

                // Clic en la red
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (model.active) return; // Si ya está conectado, no hace nada
                        if (model.security === "") {
                            // Red abierta: Conecta directo
                            connector.targetSsid = model.ssid;
                            connector.password = "";
                            connector.running = true;
                        } else {
                            // Red privada: Despliega el campo de clave
                            root.selectedIndex = root.selectedIndex === index ? -1 : index;
                        }
                    }
                }

                // Campo Desplegable de Contraseña
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
                                border.color: passField.activeFocus ? "#0a84ff" : Qt.rgba(1,1,1,0.1)
                            }
                            
                            // Conectar al presionar "Enter"
                            onAccepted: {
                                connector.targetSsid = model.ssid
                                connector.password = text
                                connector.running = true
                            }
                        }

                        // Botón "Conectar" manual
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
                                    connector.targetSsid = model.ssid
                                    connector.password = passField.text
                                    connector.running = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}