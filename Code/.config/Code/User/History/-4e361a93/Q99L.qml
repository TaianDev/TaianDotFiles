import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: triggerWindow
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 12 // Grosor de la zona interactiva inferior
    exclusiveZone: 0   // Evita desplazar las ventanas maximizadas
    color: "transparent"
    
    WlrLayershell.namespace: "launcher_trigger"
    WlrLayershell.layer: WlrLayer.Top

    property var targetLauncher: null 

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        
        property real startY: 0
        
        onPressed: (mouse) => { startY = mouse.y }
        
        // Captura el movimiento ascendente (Slide up)
        onPositionChanged: (mouse) => {
            if (startY - mouse.y > 8) { 
                if (targetLauncher && !targetLauncher.isOpened) {
                    targetLauncher.isOpened = true
                }
            }
        }
        
        // Permite abrir y cerrar mediante un clic simple en el borde
        onClicked: {
            if (targetLauncher) targetLauncher.isOpened = !targetLauncher.isOpened
        }
    }
}