import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: popup
    color: "transparent"
    implicitWidth: 360
    
    // 🌟 TAMAÑO FIJO encogido para que no sobre espacio abajo
    implicitHeight: 440

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
        clip: true // 🌟 CRUCIAL: Oculta los elementos que se deslizan fuera del recuadro

        // ── Cabecera de Navegación (Animada con Fade) ──
        Item {
            width: parent.width
            height: 40
            z: 10 // Se mantiene siempre por encima de las páginas que se deslizan
            
            // Animación de aparición suave
            opacity: popup.currentPage !== 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

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

        // ── Contenedor de Vistas (Con Slide Animation) ──
        Item {
            anchors.fill: parent
            anchors.leftMargin: 14; anchors.rightMargin: 14
            anchors.bottomMargin: 14

            // 🌟 VISTA 0: Panel Principal
            NetworkMainView {
                y: 14
                width: parent.width
                height: parent.height - y
                
                // Lógica Matemática de Deslizamiento (Se va a la Izquierda)
                property bool isActive: popup.currentPage === 0
                x: isActive ? 0 : -(parent.width + 30) 
                
                // Solo renderiza mientras es visible o está a medio camino de la animación
                visible: isActive || x > -(parent.width)
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
                
                onRequestPage: (page) => popup.currentPage = page
            }

            // 🌟 VISTA 1: Wi-Fi
            WifiPage {
                y: 44 // Respeta la cabecera
                width: parent.width
                height: parent.height - y
                
                // Lógica Matemática de Deslizamiento (Viene de la Derecha)
                property bool isActive: popup.currentPage === 1
                x: isActive ? 0 : (parent.width + 30) 
                
                visible: isActive || x < parent.width
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }

            // 🌟 VISTA 2: Bluetooth
            BluetoothPage {
                y: 44 // Respeta la cabecera
                width: parent.width
                height: parent.height - y
                
                // Lógica Matemática de Deslizamiento (Viene de la Derecha)
                property bool isActive: popup.currentPage === 2
                x: isActive ? 0 : (parent.width + 30) 
                
                visible: isActive || x < parent.width
                Behavior on x { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
            }
        }
    }
}