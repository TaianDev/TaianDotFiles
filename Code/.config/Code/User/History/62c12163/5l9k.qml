import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 414 // Altura encogida perfecta

    property var hostWindow
    property int currentPage: 0 

    anchor {
        window: popup.hostWindow
        rect: Qt.rect(popup.hostWindow ? popup.hostWindow.width - 380 : 0, 40, 360, popup.implicitHeight) 
        edges: AnchorEdge.Top | AnchorEdge.Right
    }

    onVisibleChanged: {
        if (!visible) currentPage = 0 
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(0.1, 0.1, 0.1, 0.95) 
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        clip: true // 🌟 Corta todo lo que salga del rectángulo

        // ── 1. Cabecera Fija (Solo aparece en submenús) ──
        Item {
            id: header
            width: parent.width
            height: 40
            z: 10 // Siempre arriba del carrusel
            
            opacity: popup.currentPage !== 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

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

        // ── 2. EL CARRUSEL (Track) ──
        Item {
            id: carrusel
            width: popup.width * 2  // Mide el doble de la ventana
            height: parent.height
            
            // Si es 0 (Main), está en x=0. Si es 1 o 2, se desplaza a la izquierda (-360)
            x: popup.currentPage === 0 ? 0 : -popup.width
            Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }

            // 🌟 LADO IZQUIERDO: Panel Principal
            Item {
                width: popup.width
                height: parent.height
                x: 0 // Posición inicial

                NetworkMainView {
                    anchors.fill: parent
                    anchors.margins: 14 // Los márgenes del panel principal
                    onRequestPage: (page) => popup.currentPage = page
                }
            }

            // 🌟 LADO DERECHO: Submenús (Wi-Fi y Bluetooth)
            Item {
                width: popup.width
                height: parent.height
                x: popup.width // Empieza fuera de la pantalla por la derecha

                Item {
                    anchors.fill: parent
                    anchors.topMargin: 44 // Deja espacio para la cabecera
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 14

                    WifiPage {
                        anchors.fill: parent
                        visible: popup.currentPage === 1
                    }

                    BluetoothPage {
                        anchors.fill: parent
                        visible: popup.currentPage === 2
                    }
                }
            }
        }
    }
}