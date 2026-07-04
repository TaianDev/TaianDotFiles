import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 440

    property var hostWindow
    property int currentPage: 0

    anchor {
        window: popup.hostWindow
        rect: Qt.rect(popup.hostWindow ? popup.hostWindow.width - 380 : 0, 40, 360, popup.implicitHeight)
        edges: AnchorEdge.Top | AnchorEdge.Right
    }

    onVisibleChanged: {
        if (!visible) currentPage = 0   // vuelve al menú al cerrar
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

        // ── Contenedor con deslizamiento animado ──
        // ── Contenedor con deslizamiento animado ──
Item {
    id: container
    anchors.fill: parent
    anchors.topMargin: popup.currentPage === 0 ? 14 : 44
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    anchors.bottomMargin: 14
    clip: true

    // Contenedor que se desplaza (NO Row)
    Item {
        id: pageContainer
        width: container.width * 3   // tres páginas una al lado de otra
        height: container.height
        x: -popup.currentPage * container.width

        Behavior on x {
            NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
            }
        }

        // Página 0 – Menú principal
        NetworkMainView {
            width: container.width
            height: container.height
            x: 0
            onRequestPage: (page) => popup.currentPage = page
        }

        // Página 1 – Wi‑Fi
        WifiPage {
            width: container.width
            height: container.height
            x: container.width
        }

        // Página 2 – Bluetooth
        BluetoothPage {
            width: container.width
            height: container.height
            x: container.width * 2
        }
    }
}
    }
}