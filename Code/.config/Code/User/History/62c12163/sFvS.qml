import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 360
    
    // 🌟 ANIMACIÓN DE ALTURA DINÁMICA
    // 170px para el menú compacto, 420px para las listas expandidas
    implicitHeight: 4209

    property var hostWindow
    property int currentPage: 0 

    anchor {
        window: popup.hostWindow
        rect: Qt.rect(popup.hostWindow ? popup.hostWindow.width - 380 : 0, 40, 360, popup.implicitHeight) 
        edges: AnchorEdge.Top | AnchorEdge.Right
    }

    onVisibleChanged: {
        if (!visible) currentPage = 0 // Vuelve al menú principal al cerrarse
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0.1, 0.1, 0.1, 0.95) 
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        clip: true

        // ── Cabecera de Navegación ──
        Item {
            width: parent.width
            height: 40
            visible: popup.currentPage !== 0

            Text {
                x: 16; anchors.verticalCenter: parent.verticalCenter
                text: "‹ Volver"
                color: "#0a84ff"
                font.pixelSize: 14; font.bold: true
                MouseArea {
                    anchors.fill: parent; anchors.margins: -10
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.currentPage = 0 
                }
            }
            Text {
                anchors.centerIn: parent
                text: popup.currentPage === 1 ? "Redes Wi-Fi" : "Dispositivos Bluetooth"
                color: "#ffffff"
                font.pixelSize: 14; font.bold: true
            }
            
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1
                color: Qt.rgba(1,1,1,0.1)
            }
        }

        // ── Contenedor de Vistas ──
        Item {
            anchors.fill: parent
            anchors.topMargin: popup.currentPage === 0 ? 14 : 44
            anchors.leftMargin: 14; anchors.rightMargin: 14
            anchors.bottomMargin: 14

            NetworkMainView {
                anchors.centerIn: parent
                visible: popup.currentPage === 0
                onRequestPage: (page) => popup.currentPage = page
            }

            // 🌟 FASE 2: Integración de la vista Wi-Fi real
            WifiPage {
                visible: popup.currentPage === 1
            }

            // Placeholder para Bluetooth (Próxima fase)
            BluetoothPage {
                visible: popup.currentPage === 2
            }
        }
    }
}