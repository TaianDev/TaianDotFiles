pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import "../../core"
import "../../services"
import "../../components/shell"
import "."

PopupWindow {
    id: popup

    required property var widgetRef
    required property var parentWindow

    readonly property bool open: widgetRef?.isOpened ?? false
    readonly property var trayModel: SystemTray.items
    readonly property int trayCount: trayModel.values.length

    readonly property int iconCell: 28
    readonly property int iconGap: 6
    readonly property int iconsBoxWidth: Math.max(100, Math.min(320, trayCount * (iconCell + iconGap) + 20))
    readonly property int iconsBoxHeight: 40
    readonly property int menuColumnWidth: 210
    readonly property int submenuGap: 6

    readonly property bool submenuActive: menuStack.length > 0
    readonly property int totalMenuWidth: popup.menuColumnWidth
        + (submenuActive ? popup.submenuGap + popup.menuColumnWidth : 0)

    readonly property int leftBoxHeight: Math.min(300, menuArea.leftBoxContent + 16)
    readonly property int rightBoxHeight: Math.min(300, menuArea.rightBoxContent + 16)

    readonly property int menuPanelHeight: popup.menuOpen && popup.showMenuList
        ? leftBoxHeight
        : 0

    color: "transparent"
    implicitWidth: Math.max(iconsBoxWidth, totalMenuWidth)
    implicitHeight: iconsBoxHeight + (menuOpen ? 8 + menuPanelHeight : 0)

    property real anchorLeft: 0
    property int selectedIndex: -1
    property var selectedItem: null
    property var menuStack: []
    property bool menuOpen: false

    readonly property var leftMenuHandle: selectedItem?.menu ?? null

    readonly property var rightSubHandle: {
        if (menuStack.length > 0)
            return menuStack[menuStack.length - 1]
        return null
    }

    readonly property bool showMenuList: menuOpen && selectedItem !== null
                                         && selectedItem.hasMenu

    readonly property bool rightShowBack: menuStack.length > 1

    visible: open || iconsSlide.shown || iconsSlide.exitRunning
             || menuSlide.shown || menuSlide.exitRunning

    grabFocus: open

    HyprlandFocusGrab {
        windows: [popup, parentWindow]
        active: popup.open
    }

    function reposition() {
        if (!widgetRef || !parentWindow)
            return

        const w = Math.max(100, implicitWidth)
        const h = Math.max(iconsBoxHeight, implicitHeight)
        if (w <= 0 || h <= 0)
            return

        const pos = widgetRef.mapToItem(parentWindow.contentItem, 0, widgetRef.height)
        if (!popup.menuOpen || popup.anchorLeft === 0)
            popup.anchorLeft = pos.x + widgetRef.width / 2 - w / 2

        anchor.window = parentWindow
        anchor.rect = Qt.rect(popup.anchorLeft, pos.y + 8, w, h)
        anchor.updateAnchor()
    }

    function clearSelection() {
        popup.menuOpen = false
        popup.selectedIndex = -1
        popup.selectedItem = null
        popup.menuStack = []
        popup.activeSubEntry = null
    }

    function selectItem(index, item) {
        if (index === popup.selectedIndex && popup.menuOpen) {
            menuSlide.shown = false
            popup.clearSelection()
            Qt.callLater(reposition)
            return
        }

        popup.selectedIndex = index
        popup.selectedItem = item
        popup.menuStack = []
        popup.activeSubEntry = null

        if (item.hasMenu) {
            popup.menuOpen = true
            menuSlide.shown = true
            Qt.callLater(() => {
                if (leftLoader.item)
                    leftLoader.item.bindMenu(popup.leftMenuHandle)
            })
        } else {
            item.activate()
            menuSlide.shown = false
            popup.clearSelection()
        }
        Qt.callLater(reposition)
    }

    function pushSubmenu(entry) {
        var stack = popup.menuStack.slice()
        stack.push(entry)
        popup.menuStack = stack
        Qt.callLater(reposition)
    }

    function popSubmenu() {
        if (popup.menuStack.length === 0)
            return
        var stack = popup.menuStack.slice()
        stack.pop()
        popup.menuStack = stack
        if (stack.length === 0)
            popup.activeSubEntry = null
        Qt.callLater(reposition)
    }

    property var activeSubEntry: null

    function toggleSubmenu(entry) {
        if (popup.submenuActive && popup.activeSubEntry === entry) {
            popup.menuStack = []
            popup.activeSubEntry = null
        } else {
            popup.menuStack = [entry]
            popup.activeSubEntry = entry
        }
        Qt.callLater(reposition)
    }

    function closeSubmenu() {
        popup.menuStack = []
        popup.activeSubEntry = null
        Qt.callLater(reposition)
    }

    onOpenChanged: {
        if (open) {
            popup.anchorLeft = 0
            clearSelection()
            menuSlide.shown = false
            iconsSlide.shown = true
            Qt.callLater(() => popup.contentItem.forceActiveFocus())
            Qt.callLater(reposition)
        } else {
            menuSlide.shown = false
            iconsSlide.shown = false
            clearSelection()
        }
    }

    onMenuOpenChanged: {
        if (!menuOpen) {
            menuSlide.shown = false
            popup.menuStack = []
        }
        Qt.callLater(reposition)
    }

    onImplicitHeightChanged: Qt.callLater(reposition)

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.trayId)
                widgetRef.isOpened = false
        }
    }

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(reposition)
        } else if (popup.open && !iconsSlide.exitRunning && !menuSlide.exitRunning) {
            widgetRef.isOpened = false
        }
    }

    Connections {
        target: trayModel
        function onValuesChanged() {
            if (popup.selectedIndex >= popup.trayCount)
                popup.clearSelection()
        }
    }

    PopupEscCapture {
        active: popup.open
        popupId: PopupManager.trayId

        Column {
            id: rootCol
            anchors.fill: parent
            spacing: 8

            TraySlidePanel {
                id: iconsSlide
                width: popup.menuColumnWidth
                panelHeight: popup.iconsBoxHeight
                shown: popup.open

                Rectangle {
                    width: iconsSlide.width
                    height: popup.iconsBoxHeight
                    radius: 12
                    color: Theme.background
                    border.width: 1
                    border.color: Theme.outlineVariant
                    clip: true

                    Row {
                        anchors.centerIn: parent
                        height: popup.iconCell
                        spacing: popup.iconGap

                        Repeater {
                            model: trayModel

                            Rectangle {
                                id: iconBtn
                                required property var modelData
                                required property int index

                                width: popup.iconCell
                                height: popup.iconCell
                                radius: 8
                                color: index === popup.selectedIndex
                                       ? Theme.alpha(Theme.primary, 0.18)
                                       : (iconMa.containsMouse
                                          ? Theme.alpha(Theme.inkSurf, 0.08)
                                          : Theme.alpha(Theme.surfaceVariant, 0.5))
                                border.width: index === popup.selectedIndex ? 1 : 0
                                border.color: Theme.alpha(Theme.primary, 0.45)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: iconBtn.modelData.icon
                                    sourceSize: Qt.size(16, 16)
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: true
                                }

                                MouseArea {
                                    id: iconMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.selectItem(iconBtn.index, iconBtn.modelData)
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "No tray icons"
                        color: Theme.inkSurfVar
                        font.pixelSize: 11
                        visible: trayCount === 0
                    }
                }
            }

            Item {
                id: menuArea
                width: parent.width
                height: Math.max(menuSlide.height, rightWrap.height)

                property int leftBoxContent: 64
                property int rightBoxContent: 64

                TraySlidePanel {
                    id: menuSlide
                    width: popup.menuColumnWidth
                    panelHeight: Math.min(300, menuArea.leftBoxContent + 16)
                    shown: popup.menuOpen && popup.showMenuList

                    Rectangle {
                        id: leftBox
                        width: menuSlide.width
                        height: menuSlide.panelHeight
                        radius: 12
                        color: Theme.background
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Loader {
                            id: leftLoader
                            anchors.fill: parent
                            anchors.margins: 8
                            active: popup.showMenuList
                            sourceComponent: leftMenuComponent

                            onLoaded: {
                                if (item) {
                                    menuArea.leftBoxContent = item.contentHeight
                                    item.contentHeightChanged.connect(() => {
                                        menuArea.leftBoxContent = item.contentHeight
                                    })
                                }
                            }
                        }
                    }
                }

                Item {
                    id: rightWrap
                    x: popup.menuColumnWidth + popup.submenuGap
                    anchors.top: menuSlide.top
                    width: popup.menuColumnWidth
                    height: Math.min(300, menuArea.rightBoxContent + 16)
                    opacity: popup.submenuActive ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: rightBox
                        width: popup.menuColumnWidth
                        height: parent.height
                        radius: 12
                        color: Theme.background
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Loader {
                            id: rightLoader
                            anchors.fill: parent
                            anchors.margins: 8
                            active: popup.submenuActive
                            sourceComponent: rightMenuComponent

                            property var handle: popup.rightSubHandle
                            property bool back: popup.rightShowBack

                            onLoaded: {
                                if (item) {
                                    menuArea.rightBoxContent = item.contentHeight
                                    item.contentHeightChanged.connect(() => {
                                        menuArea.rightBoxContent = item.contentHeight
                                    })
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: leftMenuComponent

                TrayMenuList {
                    menuHandle: popup.leftMenuHandle
                    showBack: false
                    onSubmenuRequested: (entry) => popup.toggleSubmenu(entry)
                    onEntryActivated: {
                        if (widgetRef)
                            widgetRef.isOpened = false
                    }
                    onContentReady: menuArea.leftBoxContent = contentHeight
                }
            }

            Component {
                id: rightMenuComponent

                TrayMenuList {
                    menuHandle: rightLoader.handle
                    showBack: rightLoader.back
                    onBackRequested: popup.popSubmenu()
                    onSubmenuRequested: (entry) => popup.pushSubmenu(entry)
                    onEntryActivated: {
                        if (widgetRef)
                            widgetRef.isOpened = false
                    }
                    onContentReady: menuArea.rightBoxContent = contentHeight
                }
            }
        }
    }
}
