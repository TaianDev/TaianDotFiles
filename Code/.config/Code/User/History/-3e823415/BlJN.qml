import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Item {
    id: root
    width: 320
    height: 140

    property string iconsPath: "file:///home/taianlux/.config/quickshell/assets/icons/"
    signal requestPage(int pageIndex) 

    // Datos Bluetooth
    property var btAdapter: Bluetooth.defaultAdapter
    property bool btEnabled: btAdapter?.enabled ?? false
    property string btDeviceName: {
        if (!btAdapter) return "Desconectado"
        const devs = btAdapter.devices.values
        for (let i=0; i < devs.length; i++) {
            if (devs[i].connected) return devs[i].name
        }
        return "Desconectado"
    }

    // Datos Wi-Fi (Simulados hasta integrar NetworkManager)
    property bool wifiEnabled: true
    property string wifiNetwork: "Shang_Kaishuang_2.4G"
    
    property bool airplaneMode: false

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            spacing: 12
            Layout.alignment: Qt.AlignHCenter

            NetworkToggle {
                title: "Wi-Fi"
                subtitle: root.wifiEnabled ? root.wifiNetwork : "Apagado"
                isToggled: root.wifiEnabled
                iconSource: root.wifiEnabled ? root.iconsPath + "wifi-full.svg" : root.iconsPath + "no-wifi.svg"
                iconTint: root.wifiEnabled ? "#0a84ff" : "#ffffff" 
                onToggleClicked: root.wifiEnabled = !root.wifiEnabled
                onArrowClicked: root.requestPage(1) 
            }

            NetworkToggle {
                title: "Bluetooth"
                subtitle: root.btEnabled ? root.btDeviceName : "Apagado"
                isToggled: root.btEnabled
                iconSource: root.btEnabled ? root.iconsPath + "bluetooth.svg" : root.iconsPath + "no-bluetooth.svg"
                iconTint: root.btEnabled ? "#0a84ff" : "#ffffff"
                onToggleClicked: if(root.btAdapter) root.btAdapter.enabled = !root.btAdapter.enabled
                onArrowClicked: root.requestPage(2) 
            }
        }

        // Modo Avión
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
                        onClicked: root.airplaneMode = !root.airplaneMode
                    }
                }
            }
        }
    }
}