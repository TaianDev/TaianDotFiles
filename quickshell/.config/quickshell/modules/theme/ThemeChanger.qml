import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../components/shell"

PanelWindow {
    id: themeChanger
    color: "transparent"
    implicitHeight: 480

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property bool isOpened: false
    property string currentPath: ""
    property string activeWallpaperPath: ""

    anchors { bottom: true; left: true; right: true }
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_theme"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    visible: isOpened

    WallpaperService { id: wallpaperService }

    Connections {
        target: wallpaperService
        function onApplied(path) { closeTimer.start() }
    }

    Timer {
        id: closeTimer
        interval: 300
        onTriggered: themeChanger.isOpened = false
    }

    IpcHandler {
        target: "theme_panel"
        function toggle(): void {
            if (themeChanger.isOpened) { themeChanger.isOpened = false }
            else {
                PopupManager.openExclusive(PopupManager.themeId)
                Qt.callLater(() => themeChanger.isOpened = true)
            }
        }
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.themeId) themeChanger.isOpened = false
        }
    }

    onIsOpenedChanged: {
        if (!isOpened) PopupManager.notifyClosed(PopupManager.themeId)
        if (isOpened) {
            if (currentPath === "" && AppPaths.homeDir !== "") currentPath = AppPaths.wallpapersPath
            wallGrid.searchText = ""
            wallGrid.forceSearchFocus()
        }
    }

    Connections {
        target: AppPaths
        function onHomeDirChanged() {
            if (themeChanger.currentPath === "" && AppPaths.homeDir !== "")
                themeChanger.currentPath = AppPaths.wallpapersPath
        }
    }

    function applyWallpaper(path) { wallpaperService.apply(path) }

    PopupEscCapture {
        active: themeChanger.isOpened
        popupId: PopupManager.themeId

        ConcaveBottomPanel {
            panelWidth: 900; panelHeight: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            WallpaperGrid {
                id: wallGrid
                anchors.fill: parent
                currentPath: themeChanger.currentPath
                activeWallpaperPath: themeChanger.activeWallpaperPath
                iconsPath: themeChanger.iconsPath
                onWallpaperSelected: path => {
                    themeChanger.activeWallpaperPath = path
                    themeChanger.applyWallpaper(path)
                }
                onCloseRequested: themeChanger.isOpened = false
            }
        }
    }
}
