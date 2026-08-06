pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    readonly property string dateId: "date"
    readonly property string musicId: "music"
    readonly property string trayId: "tray"
    readonly property string networkId: "network"
    readonly property string notificationsId: "notifications"
    readonly property string launcherId: "launcher"
    readonly property string themeId: "theme"
    readonly property string assistantId: "assistant"
    property string activeId: ""
    property bool escapeBound: false

    signal closeRequested(string id)
    signal toggleMusicRequested()
    signal toggleNetworkRequested()
    signal toggleDateRequested()

    readonly property bool hasOpen: activeId !== ""

    IpcHandler {
        target: "bar_popup"
        function close(): void {
            root.closeActive()
        }
    }

    IpcHandler {
        target: "music_popup"
        function toggle(): void {
            root.toggleMusicRequested()
        }
    }

    IpcHandler {
        target: "network_popup"
        function toggle(): void {
            root.toggleNetworkRequested()
        }
    }

    IpcHandler {
        target: "date_popup"
        function toggle(): void {
            root.toggleDateRequested()
        }
    }

    function bindEscape() {
        if (root.escapeBound)
            return
        Quickshell.execDetached([
            "hyprctl", "keyword",
            "bind , Escape, exec, qs ipc call bar_popup close"
        ])
        root.escapeBound = true
    }

    function unbindEscape() {
        if (!root.escapeBound)
            return
        Quickshell.execDetached(["hyprctl", "keyword", "unbind , Escape"])
        root.escapeBound = false
    }

    function openExclusive(id) {
        if (id === "")
            return

        if (activeId !== "" && activeId !== id)
            root.closeRequested(activeId)

        root.activeId = id
        root.bindEscape()
    }

    function notifyClosed(id) {
        if (root.activeId === id) {
            root.activeId = ""
            root.unbindEscape()
        }
    }

    function closeActive() {
        if (root.activeId === "")
            return
        root.closeRequested(root.activeId)
    }

    function requestOpen(id) {
        root.openExclusive(id)
    }

    function requestClose(id) {
        if (root.activeId === id)
            root.closeRequested(id)
    }
}
