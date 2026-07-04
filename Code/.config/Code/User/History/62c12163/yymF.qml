import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 400

    property var hostWindow
    property int currentPage: 0 

    anchor {
        window: popup.hostWindow
        rect: Qt.rect(hostWindow.width - 380, 40, 360, 400) 
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
                text: popup.currentPage === 1 ? "Wi-Fi" : "Bluetooth"
                color: "#ffffff"
                font.pixelSize: 14; font.bold: true
            }
        }

        // ── Vistas ──
        Item {
            anchors.fill: parent
            anchors.topMargin: popup.currentPage === 0 ? 20 : 50
            anchors.leftMargin: 20; anchors.rightMargin: 20

            NetworkMainView {
                anchors.centerIn: parent
                visible: popup.currentPage === 0
                onRequestPage: (page) => popup.currentPage = page
            }

            Text {
                anchors.centerIn: parent
                visible: popup.currentPage === 1
                color: "#ffffff"
                text: "Lista de Redes Wi-Fi\n(Desarrollo en Fase 2)"
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                anchors.centerIn: parent
                visible: popup.currentPage === 2
                color: "#ffffff"
                text: "Lista de Dispositivos BT\n(Desarrollo en Fase 2)"
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}