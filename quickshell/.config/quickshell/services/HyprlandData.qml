pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../utils"

Item {
    id: root
    visible: false

    property var windowList: []
    property var windowByAddress: ({})

    readonly property string fallbackIconPath: IconResolver.fallbackAppIcon()

    function updateWindowList() { getClients.running = true }

    function hyprlandClientsForWorkspace(workspaceId) {
        return root.windowList.filter(win => win.workspace?.id === workspaceId)
    }

    function iconsForWorkspace(workspaceId) {
        return hyprlandClientsForWorkspace(workspaceId)
            .map(win => iconForWindow(win))
            .filter(path => path !== "")
    }

    function iconForWindow(win) { return IconResolver.iconForWindow(win) }

    Component.onCompleted: updateWindowList()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].includes(event.name)) return
            root.updateWindowList()
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root.updateWindowList() }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text)
                    root.windowList = list
                    const map = {}
                    for (let i = 0; i < list.length; ++i) {
                        const win = list[i]
                        map[win.address] = win
                    }
                    root.windowByAddress = map
                } catch (e) {
                    console.warn("[HyprlandData] parse error:", e)
                }
            }
        }
    }
}
