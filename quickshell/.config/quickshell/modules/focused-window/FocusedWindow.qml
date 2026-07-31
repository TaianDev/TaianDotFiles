import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../core"
import "../../components"

Item {
    id: root

    property string windowTitle: ""
    property string windowAppId: ""

    function formatAppId(raw) {
        if (!raw) return "Hyprland"
        const parts = raw.split(".")
        const last = parts[parts.length - 1]
        return last.charAt(0).toUpperCase() + last.slice(1) + " - Hyprland"
    }

    function formatTitle(raw) {
        if (!raw) return "Desktop - Hyprland"
        if (raw.length > 37) return raw.substring(0, 25) + "..."
        return raw
    }

    readonly property string displayAppId: formatAppId(windowAppId)
    readonly property string displayTitle: formatTitle(windowTitle)

    Process {
        id: fetchProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text.trim())
                    root.windowTitle = data?.title ?? ""
                    root.windowAppId = data?.class ?? ""
                } catch (_) {}
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = `${event?.name ?? event?.event ?? event?.type ?? ""}`
            if (name === "activewindow" || name === "activewindowv2")
                fetchProc.running = true
        }
    }

    property bool _inited: false

    onDisplayTitleChanged: {
        if (!_inited) return
        fadeAnim.restart()
    }

    SequentialAnimation {
        id: fadeAnim
        PropertyAnimation { target: textColumn; property: "opacity"; to: 0.4; duration: 60 }
        PropertyAnimation { target: textColumn; property: "opacity"; to: 1.0; duration: 100 }
    }

    Component.onCompleted: {
        fetchProc.running = true
        Qt.callLater(() => _inited = true)
    }

    implicitHeight: 28
    implicitWidth: Math.min(textRow.implicitWidth, 260)

    Row {
        id: textRow
        height: parent.height
        spacing: 6

        SvgIcon {
            anchors.verticalCenter: parent.verticalCenter
            source: AppPaths.iconsDir + "arch.svg"
            size: 16
            tint: Theme.inkSurf
        }

        Column {
            id: textColumn
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

            Text {
                text: root.displayAppId
                color: Qt.rgba(1, 1, 1, 0.45)
                font.pixelSize: 9
            }

            Text {
                text: root.displayTitle
                color: Theme.inkSurf
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }
        }
    }
}
