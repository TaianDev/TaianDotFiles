import QtQuick
import Quickshell
import Quickshell.Wayland
import "LauncherTrigger"
PanelWindow {
    id: triggerWindow
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 12
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "launcher_trigger"
    WlrLayershell.layer: WlrLayer.Top

    property var targetLauncher: null

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        property real pressY: 0
        property bool dragged: false

        onPressed: (mouse) => {
            pressY = mouse.y
            dragged = false
        }

        onPositionChanged: (mouse) => {
            if (!dragged && pressY - mouse.y > 8) {
                dragged = true
                if (targetLauncher && !targetLauncher.isOpened) {
                    // 🌟 CORRECCIÓN 2: Le dice al lanzador global que se ancle a esta pantalla
                    targetLauncher.anchor.window = triggerWindow
                    targetLauncher.isOpened = true
                }
            }
        }

        onClicked: {
            if (!dragged && targetLauncher) {
                // 🌟 CORRECCIÓN 2 (Clic): Anclaje dinámico
                if (!targetLauncher.isOpened) {
                    targetLauncher.anchor.window = triggerWindow
                }
                targetLauncher.isOpened = !targetLauncher.isOpened
            }
        }
    }
}