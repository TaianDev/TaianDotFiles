import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: wsContainer
    spacing: 8

    // Recibe el nombre físico del puerto (ej. "HDMI-A-1", "DP-1")
    required property string outputName

    // LÓGICA DE MONITORES: Si el nombre incluye "HDMI", usa 1-5. Si no, 6-10.
    property var targetWorkspaces: outputName.indexOf("HDMI") !== -1 ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

    Repeater {
        model: targetWorkspaces

        Rectangle {
            id: pill
            property int wsId: modelData
            
            // Conexión en vivo con el estado interno de Hyprland
            property var hyprWorkspace: Hyprland.workspace(wsId)
            
            // Evaluación de los 3 estados
            property bool isActive: Hyprland.activeWorkspace.id === wsId
            property bool isOccupied: hyprWorkspace != null && hyprWorkspace.windows > 0

            // Animaciones fluidas de expansión y color
            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
            Behavior on color { ColorAnimation { duration: 200 } }

            // DIMENSIONES: "Pastilla" ancha si está activo, "Punto" si no
            width: isActive ? 32 : 12
            height: 12
            radius: 6 // Mitad de la altura para que sea perfectamente circular en los bordes

            // COLORES DE ESTADO
            color: {
                if (isActive) return "#8cf0c3"       // Activo: Verde de tu tema anterior
                if (isOccupied) return "#ffffff"     // Ocupado: Blanco sólido
                return "#333333"                     // Vacío: Gris oscuro (casi invisible)
            }

            // INTERACCIÓN: Click para viajar a ese espacio
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace", wsId.toString())
            }
        }
    }
}