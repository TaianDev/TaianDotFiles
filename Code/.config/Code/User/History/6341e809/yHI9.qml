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
    property int selectedIndex: -1 

    ListModel { id: wifiModel }

    // ── 1. Escáner Inteligente de Redes (Escritura en archivo temporal) ──
    Process {
        id: scanner
        // Redirigimos la salida al archivo /tmp/quickshell_wifi_scan.out
        command: ["bash", "-c", "nmcli -t -f SSID,SECURITY,ACTIVE,SIGNAL dev wifi | grep -v '^:' > /tmp/quickshell_wifi_scan.out"]
        running: root.visible
        
        // Cuando el escaneo termina, leemos el archivo
        onExited: (code) => {
            try {
                let output = File.read("/tmp/quickshell_wifi_scan.out");
                wifiModel.clear();
                const lines = output.trim().split('\n');
                
                let activeNet = null;
                let otherMap = {};

                for(let line of lines) {
                    if(line === "") continue;
                    const parts = line.split(':');
                    if(parts.length >= 4 && parts[0] !== "") {
                        let ssid = parts[0];
                        let security = parts[1];
                        let isActive = (parts[2] === "yes" || parts[2] === "sí" || parts[2] === "true");
                        let signal = parseInt(parts[3]);

                        if (isActive) {
                            activeNet = { ssid: ssid, security: security, active: true, signal: signal };
                        } else {
                            if (!otherMap[ssid] || otherMap[ssid].signal < signal) {
                                otherMap[ssid] = { ssid: ssid, security: security, active: false, signal: signal };
                            }
                        }
                    }
                }

                // Posiciona la red conectada primero
                if (activeNet) {
                    wifiModel.append(activeNet);
                    delete otherMap[activeNet.ssid]; 
                }

                // Agrega las demás redes
                for (let key in otherMap) {
                    wifiModel.append(otherMap[key]);
                }
            } catch (e) {
                // Silencio si el archivo aún no se crea
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
            root.selectedIndex = -1 
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
                height: isExpanded ? 80 : 44
                radius: 10
                color: model.active ? Qt.rgba(0.2, 0.6, 1.0, 0.2) : (ma.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent")
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuart } }

                property bool isExpanded: root.selectedIndex === index && !model.active && model.security !== ""

                RowLayout {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 44
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Ícono de Señal (Pintado con ColorOverlay)
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

                    // Nombre de la red
                    Text {
                        Layout.fillWidth: true
                        text: model.ssid
                        color: model.active ? "#0a84ff" : "#ffffff"
                        font.pixelSize: 13
                        font.bold: model.active
                        elide: Text.ElideRight
                    }

                    // Ícono de Candado
                    Item {
                        visible: model.security !== "" && !model.active 
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

                // Zona de Clic
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (model.active) return; 
                        if (model.security === "") {
                            connector.targetSsid = model.ssid;
                            connector.password = "";
                            connector.running = true;
                        } else {
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
                            
                            onAccepted: {
                                connector.targetSsid = model.ssid
                                connector.password = text
                                connector.running = true
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