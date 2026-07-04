import QtQuick
import Quickshell
import Quickshell.Wayland

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
                    targetLauncher.screen = triggerWindow.screen
                    targetLauncher.isOpened = true
                }
            }
        }

        onClicked: {
            if (!dragged && targetLauncher) {
                if (!targetLauncher.isOpened) {
                    targetLauncher.screen = triggerWindow.screen
                }
                targetLauncher.isOpened = !targetLauncher.isOpened
            }
        }
    }
}