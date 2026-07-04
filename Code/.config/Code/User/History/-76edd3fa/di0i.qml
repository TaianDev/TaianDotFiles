import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Item {
    id: wsContainer

    property string outputName
    property var targetWorkspaces: outputName === "HDMI-A-1" ? [1, 2, 3, 4, 5] : [6, 7, 8, 9, 10]

    property int wsSize: 28        // tamaño de cada celda de workspace
    property int iconSize: 18      // tamaño del ícono
    property int dotSize: 5        // tamaño del punto (workspace vacío)
    property int pillHeight: 3     // altura de la pastilla indicadora
    property int pillWidth: 16     // ancho de la pastilla indicadora

    // Lista de workspaces ocupados (existe en Hyprland = tiene al menos 1 ventana)
    property list<bool> workspaceOccupied: []

    function updateWorkspaceOccupied() {
        workspaceOccupied = targetWorkspaces.map(wsId =>
            Hyprland.workspaces.values.some(ws => ws.id === wsId)
        )
    }

    Component.onCompleted: updateWorkspaceOccupied()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { wsContainer.updateWorkspaceOccupied() }
    }

    // Índice activo dentro de targetWorkspaces
    property int activeIndex: {
        for (let i = 0; i < targetWorkspaces.length; i++) {
            let ws = Hyprland.workspaces.values.find(w => w.id === targetWorkspaces[i])
            if (ws && ws.active) return i
        }
        return 0
    }

    implicitWidth: wsSize * targetWorkspaces.length
    implicitHeight: wsSize + pillHeight + 2

    // Pastilla indicadora animada
    Rectangle {
        id: activePill
        width: pillWidth
        height: pillHeight
        radius: pillHeight / 2
        color: "#b4a7f5"   // morado suave, igual a la imagen
        anchors.bottom: parent.bottom

        x: wsContainer.activeIndex * wsSize + (wsSize - pillWidth) / 2

        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }

    // Fila de workspaces
    Row {
        id: wsRow
        anchors.top: parent.top
        spacing: 0

        Repeater {
            model: targetWorkspaces

            Item {
                id: wsCell
                width: wsSize
                height: wsSize

                property int wsId: modelData
                property int wsIndex: index
                property HyprlandWorkspace hyprWorkspace: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                property bool isActive: hyprWorkspace?.active ?? false
                property bool isOccupied: wsContainer.workspaceOccupied[wsIndex] ?? false

                // Ícono de la app principal del workspace
                // toplevels.values[0] es la primera ventana en ese workspace
property var firstToplevel: hyprWorkspace?.toplevels?.values[0] ?? null
property string appClass: firstToplevel?.wayland?.appId ?? ""
                property string iconSource: appClass !== ""
                    ? Quickshell.iconPath(appClass, "application-x-executable")
                    : ""

                // Ícono (visible si workspace ocupado)
                Item {
                    anchors.centerIn: parent
                    width: iconSize
                    height: iconSize
                    opacity: isOccupied ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    IconImage {
                        anchors.fill: parent
                        source: wsCell.iconSource
                        implicitSize: iconSize
                    }
                }

                // Punto (visible si workspace vacío)
                Rectangle {
                    anchors.centerIn: parent
                    width: dotSize
                    height: dotSize
                    radius: dotSize / 2
                    color: isActive ? "#ffffff" : "#666666"
                    opacity: isOccupied ? 0 : 1
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                // Click para cambiar workspace
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("focusmonitor " + wsContainer.outputName)
                        Hyprland.dispatch("workspace " + wsId)
                    }
                }
            }
        }
    }
}
