pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root
    visible: false

    property var windowList: []
    property var windowByAddress: ({})

    readonly property string fallbackIconPath: {
        const names = [
            "application-x-executable",
            "application-default-icon",
            "preferences-system-windows",
            "window-new"
        ]
        for (let i = 0; i < names.length; i++) {
            const path = resolveThemeIcon(names[i])
            if (path !== "")
                return path
        }
        return ""
    }

    function updateWindowList() {
        getClients.running = true
    }

    function hyprlandClientsForWorkspace(workspaceId) {
        return root.windowList.filter(win => win.workspace?.id === workspaceId)
    }

    function iconsForWorkspace(workspaceId) {
        return hyprlandClientsForWorkspace(workspaceId)
            .map(win => iconForWindow(win))
            .filter(path => path !== "")
    }

    function addCandidate(list, seen, name) {
        if (!name || typeof name !== "string")
            return
        name = name.trim()
        if (name === "" || seen[name])
            return
        seen[name] = true
        list.push(name)
    }

    function iconCandidatesForWindow(win) {
        const out = []
        const seen = {}
        const cls = win?.class ?? ""
        const initial = win?.initialClass ?? ""

        const aliases = {
            "Spotify": ["spotify", "com.spotify.Client"],
            "spotify": ["spotify", "com.spotify.Client"],
            "zen": ["zen-browser", "io.github.zen_browser.zen"],
            "cursor": ["cursor", "co.anysphere.cursor", "visual-studio-code", "code"],
            "code": ["code", "visual-studio-code"],
            "Code": ["code", "visual-studio-code"],
            "firefox": ["firefox"],
            "chromium": ["chromium", "google-chrome"],
            "google-chrome": ["google-chrome"],
            "kitty": ["kitty"],
            "foot": ["foot"],
            "alacritty": ["Alacritty", "alacritty"],
        }

        addCandidate(out, seen, cls)
        addCandidate(out, seen, initial)
        addCandidate(out, seen, cls.toLowerCase())
        addCandidate(out, seen, initial.toLowerCase())

        const keys = [cls, initial, cls.toLowerCase(), initial.toLowerCase()]
        for (let k = 0; k < keys.length; k++) {
            const key = keys[k]
            const mapped = aliases[key]
            if (!mapped)
                continue
            for (let i = 0; i < mapped.length; i++)
                addCandidate(out, seen, mapped[i])
        }

        const lookupId = cls || initial
        if (lookupId !== "") {
            const entry = DesktopEntries.byId(lookupId)
            if (entry?.icon)
                addCandidate(out, seen, entry.icon)

            const heuristic = DesktopEntries.heuristicLookup(lookupId)
            if (heuristic?.icon)
                addCandidate(out, seen, heuristic.icon)
            if (heuristic?.id) {
                const hEntry = DesktopEntries.byId(heuristic.id)
                if (hEntry?.icon)
                    addCandidate(out, seen, hEntry.icon)
            }
        }

        return out
    }

    function resolveThemeIcon(name) {
        if (!name || name.trim() === "")
            return ""
        if (!Quickshell.hasThemeIcon(name))
            return ""
        const path = Quickshell.iconPath(name)
        return path !== "" ? path : ""
    }

    function iconForWindow(win) {
        if (!win)
            return ""

        const candidates = iconCandidatesForWindow(win)
        for (let i = 0; i < candidates.length; i++) {
            const path = resolveThemeIcon(candidates[i])
            if (path !== "")
                return path
        }

        return root.fallbackIconPath
    }

    Component.onCompleted: updateWindowList()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["openlayer", "closelayer", "screencast"].includes(event.name))
                return
            root.updateWindowList()
        }
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            root.updateWindowList()
        }
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
