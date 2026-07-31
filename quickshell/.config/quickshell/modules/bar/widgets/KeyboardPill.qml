import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../../components"
import "../../../core"

Item {
    id: root

    property string iconsPath: AppPaths.iconsDir
    property int iconSize: 16
    property string activeLayout: ""

    implicitWidth: 28 + (layoutText.visible ? layoutText.implicitWidth + 2 : 0)
    implicitHeight: 28

    Process {
        id: layoutProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim())
                    const kbs = data.keyboards
                    if (!kbs || kbs.length === 0) return
                    const kb = kbs.find(k => k.main) ?? kbs[0]
                    const km = (kb.active_keymap ?? "").split("(")[0].trim()
                    root.activeLayout = km.substring(0, 2).toUpperCase()
                } catch (_) {}
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const name = `${event?.name ?? event?.event ?? ""}`
            if (name === "activelayout")
                layoutProc.running = true
        }
    }

    Component.onCompleted: layoutProc.running = true

    SvgIcon {
        id: svgIcon
        anchors.verticalCenter: parent.verticalCenter
        x: 6
        source: root.iconsPath + "keyboard.svg"
        size: root.iconSize
        tint: Theme.inkSurf
        opacity: ma.containsMouse ? 0.65 : 1.0
        Behavior on opacity { ColorAnimation { duration: 150 } }
    }

    Text {
        id: layoutText
        anchors.left: svgIcon.right
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.activeLayout
        color: Theme.inkSurf
        font.pixelSize: 9
        font.bold: true
        visible: text !== ""
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: layoutProc.running = true
    }
}
