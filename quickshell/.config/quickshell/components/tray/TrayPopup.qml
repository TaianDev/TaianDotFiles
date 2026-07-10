pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../../core"
import "../../services"
import "../shell"
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
    readonly property int menuPanelHeight: popup.menuOpen && popup.showMenuList
        ? Math.min(300, Math.max(72, menuBody.contentHeight + 16))
        : 0

    color: "transparent"
    implicitWidth: iconsBoxWidth
    implicitHeight: iconsBoxHeight + (menuOpen ? 8 + menuPanelHeight : 0)

    property int selectedIndex: -1
    property var selectedItem: null
    property var menuStack: []
    property bool menuOpen: false
    property int menuEpoch: 0

    readonly property var currentMenuHandle: {
        if (menuStack.length > 0)
            return menuStack[menuStack.length - 1]
        return selectedItem?.menu ?? null
    }

    readonly property bool showMenuList: menuOpen && selectedItem !== null
                                         && (selectedItem.hasMenu || menuStack.length > 0)

    visible: open || iconsSlide.shown || iconsSlide.exitRunning
             || menuSlide.shown || menuSlide.exitRunning

    grabFocus: open

    function reposition() {
        if (!widgetRef || !parentWindow)
            return

        const w = Math.max(100, implicitWidth)
        const h = Math.max(iconsBoxHeight, implicitHeight)
        if (w <= 0 || h <= 0)
            return

        const pos = widgetRef.mapToItem(parentWindow.contentItem, 0, widgetRef.height)
        const ax = pos.x + widgetRef.width / 2 - w / 2
        anchor.window = parentWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, w, h)
        anchor.updateAnchor()
    }

    function clearSelection() {
        popup.menuOpen = false
        popup.selectedIndex = -1
        popup.selectedItem = null
        popup.menuStack = []
    }

    function reopenMenuSlide() {
        menuSlide.shown = false
        Qt.callLater(() => {
            if (popup.menuOpen)
                menuSlide.shown = true
            reposition()
        })
    }

    function selectItem(index, item) {
        if (index === popup.selectedIndex && popup.menuOpen) {
            menuSlide.shown = false
            popup.clearSelection()
            Qt.callLater(reposition)
            return
        }

        const switching = popup.menuOpen && popup.selectedItem !== null

        popup.selectedIndex = index
        popup.selectedItem = item
        popup.menuStack = []
        popup.menuEpoch++

        if (item.hasMenu) {
            popup.menuOpen = true
            if (switching)
                popup.reopenMenuSlide()
            else
                menuSlide.shown = true
        } else {
            item.activate()
            menuSlide.shown = false
            popup.clearSelection()
        }
        Qt.callLater(reposition)
    }

    function pushSubmenu(entry) {
        const stack = popup.menuStack.slice()
        stack.push(entry)
        popup.menuStack = stack
        popup.menuEpoch++
        entry.updateLayout()
        popup.reopenMenuSlide()
    }

    function popSubmenu() {
        if (popup.menuStack.length === 0)
            return
        const stack = popup.menuStack.slice()
        stack.pop()
        popup.menuStack = stack
        popup.menuEpoch++
        popup.reopenMenuSlide()
    }

    onOpenChanged: {
        if (open) {
            clearSelection()
            menuSlide.shown = false
            iconsSlide.shown = true
            Qt.callLater(reposition)
        } else {
            menuSlide.shown = false
            iconsSlide.shown = false
            clearSelection()
        }
    }

    onMenuOpenChanged: {
        if (!menuOpen)
            menuSlide.shown = false
        Qt.callLater(reposition)
    }

    onImplicitHeightChanged: Qt.callLater(reposition)

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
            width: parent.width
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

        TraySlidePanel {
            id: menuSlide
            width: parent.width
            panelHeight: popup.menuPanelHeight
            shown: popup.menuOpen && popup.showMenuList

            Rectangle {
                id: menuBody
                width: menuSlide.width
                height: popup.menuPanelHeight
                radius: 12
                color: Theme.background
                border.width: 1
                border.color: Theme.outlineVariant
                clip: true

                property int contentHeight: 64

                Loader {
                    id: menuLoader
                    anchors.fill: parent
                    anchors.margins: 8
                    active: popup.showMenuList
                    sourceComponent: menuListComponent

                    property var handle: popup.currentMenuHandle
                    property bool back: popup.menuStack.length > 0
                    property int epoch: popup.menuEpoch

                    onLoaded: {
                        if (item) {
                            menuBody.contentHeight = item.contentHeight
                            item.contentReady.connect(() => {
                                menuBody.contentHeight = item.contentHeight
                                Qt.callLater(popup.reposition)
                            })
                        }
                    }

                    onEpochChanged: {
                        if (!active)
                            return
                        active = false
                        Qt.callLater(() => menuLoader.active = true)
                    }
                }

                Component {
                    id: menuListComponent

                    TrayMenuList {
                        menuHandle: menuLoader.handle
                        showBack: menuLoader.back
                        onBackRequested: popup.popSubmenu()
                        onSubmenuRequested: (entry) => popup.pushSubmenu(entry)
                        onEntryActivated: {
                            if (widgetRef)
                                widgetRef.isOpened = false
                        }
                        onContentReady: menuBody.contentHeight = contentHeight
                    }
                }
            }
        }
    }
    }
}
