import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: activateLinuxWindow

    // Quickshell inyectará automáticamente 'modelData' (el monitor actual) 
    // gracias al bloque Variants de tu archivo principal.
    property var modelData
    screen: modelData

    anchors {
        right: true
        bottom: true
    }

    margins {
        right: 50
        bottom: 50
    }

    implicitWidth: content.width
    implicitHeight: content.height

    color: "transparent"

    // IMPORTANTE: Máscara vacía para que los clics pasen a través de las letras
    // y no te bloqueen el escritorio.
    mask: Region {}

    // La capa Overlay asegura que se vea incluso por encima de juegos
    // o videos a pantalla completa.
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: content

        Text {
            text: "Activate Linux"
            color: "#50ffffff" // Blanco con transparencia
            font.pointSize: 22
        }

        Text {
            text: "Go to Settings to activate Linux"
            color: "#50ffffff"
            font.pointSize: 14
        }
    }
}