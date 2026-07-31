import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../../core"
import "../../services"
import "../../components/shell"
import "../../utils"

PopupWindow {
    id: popup

    required property var widgetRef
    required property var parentWindow

    readonly property bool open: widgetRef?.popupOpen ?? false

    grabFocus: open

    HyprlandFocusGrab {
        windows: [popup, parentWindow]
        active: popup.open
    }

    readonly property int mainWidth: 300
    readonly property int volumePanelWidth: 52
    readonly property int volumeGap: 8
    readonly property bool volumeSupported: popup.player?.volumeSupported ?? false

    property bool volumeOpen: false
    property bool _slideBackward: false
    property bool _fadeTransition: false

    visible: open || shell.exitRunning || volumeFade.shown || volumeFade.exitRunning
    color: "transparent"
    implicitWidth: popup.mainWidth
        + (popup.volumeOpen && popup.volumeSupported
            ? popup.volumeGap + popup.volumePanelWidth : 0)
    implicitHeight: contentCol.implicitHeight + 48

    function reposition() {
        if (!widgetRef || !parentWindow) return
        const totalW = Math.max(popup.mainWidth, implicitWidth)
        const h = Math.max(1, implicitHeight)
        const pos = widgetRef.mapToItem(parentWindow.contentItem, 0, widgetRef.height)
        const ax = pos.x + widgetRef.width / 2 - popup.mainWidth / 2
        anchor.window = parentWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, totalW, h)
        anchor.updateAnchor()
    }

    onOpenChanged: {
        if (open) { reposition(); shell.active = true; Qt.callLater(() => popup.contentItem.forceActiveFocus()) }
        else { shell.active = false; popup.volumeOpen = false }
    }

    readonly property var    player:      widgetRef?.player      ?? null
    readonly property bool   playing:     widgetRef?.playing     ?? false
    readonly property string trackTitle:  widgetRef?.trackTitle  ?? ""
    readonly property string trackArtist: widgetRef?.trackArtist ?? ""
    readonly property string trackAlbum:  player?.trackAlbum     ?? ""
    readonly property string iconsPath:   widgetRef?.iconsPath   ?? ""
    readonly property var    playerList:  widgetRef?.playerList  ?? []

    readonly property string stableArtUrl: widgetRef?.stableArtUrl ?? ""

    readonly property string selectedPkey: {
        const p = playerList.length > 0
            ? playerList[widgetRef?.activePlayerIndex ?? 0] : null
        return p?.playerName ?? p?.identity ?? "unknown"
    }
    readonly property string selectedArtUrl: widgetRef?.artCache?.[selectedPkey] ?? ""
    readonly property string displayArtUrl: selectedArtUrl !== "" ? selectedArtUrl : stableArtUrl

    readonly property bool repeatOnceSupported: popup.player?.loopSupported ?? false
    readonly property bool repeatOnceActive: popup.player?.loopState === MprisLoopState.Track

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.musicId)
                widgetRef.popupOpen = false
        }
    }

    onVisibleChanged: {
        if (visible) reposition()
        else if (popup.open && !shell.exitRunning && !volumeFade.shown && !volumeFade.exitRunning)
            widgetRef.popupOpen = false
    }

    onVolumeOpenChanged: Qt.callLater(reposition)
    onImplicitWidthChanged: Qt.callLater(reposition)

    readonly property bool lengthValid:   (player?.length ?? 0) > 0
    readonly property bool positionValid: player?.positionSupported ?? false
    readonly property real positionSecs:  player?.position ?? 0
    readonly property real lengthSecs:    player?.length ?? 0
    readonly property real progress: (lengthValid && positionValid)
        ? Math.min(1, positionSecs / lengthSecs) : 0

    Timer {
        running: popup.playing && popup.visible && popup.positionValid
        interval: 250; repeat: true
        onTriggered: if (popup.player) popup.player.positionChanged()
    }

    PopupEscCapture {
        active: popup.open
        popupId: PopupManager.musicId

        Row {
            id: popupRow
            anchors.fill: parent
            spacing: popup.volumeGap

            Item {
                width: popup.mainWidth
                height: popupRow.height

                PopupEnterExit {
                    id: shell
                    anchors.fill: parent
                    active: popup.open
                    cornerRadius: 16
                    panelColor: "transparent"

                    Item {
                        id: bubbleContent
                        anchors.fill: parent

                        Item {
                            id: artBackground
                            anchors.fill: parent

                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Rectangle {
                                    width: artBackground.width
                                    height: artBackground.height
                                    radius: shell.cornerRadius
                                }
                            }

                            Item {
                                anchors.fill: parent
                                visible: popup.displayArtUrl !== ""

                                Image {
                                    id: popupBg
                                    anchors.centerIn: parent
                                    source: popup.displayArtUrl
                                    width: parent.width + 60; height: parent.height + 60
                                    fillMode: Image.PreserveAspectCrop
                                    cache: true
                                    asynchronous: true
                                    sourceSize: Qt.size(200, 200)

                                    Behavior on source {
                                        SequentialAnimation {
                                        NumberAnimation { target: popupBg; property: "opacity"; to: 0; duration: 150 }
                                        PropertyAction { target: popupBg; property: "opacity"; value: 0 }
                                        NumberAnimation { target: popupBg; property: "opacity"; to: 1; duration: 250 }
                                        }
                                    }
                                }

                                FastBlur {
                                    anchors.fill: popupBg
                                    source: popupBg
                                    radius: 60
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(0, 0, 0, 0.68)
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: popup.displayArtUrl === ""
                                color: ColorUtils.alpha(Theme.background, 0.92)
                            }
                        }

                        Column {
                            id: contentCol
                            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
                            spacing: 14

                            PlayerRow {
                                id: playerRow
                                anchors.horizontalCenter: parent.horizontalCenter
                                playerList: popup.playerList
                                activeIndex: popup.widgetRef?.activePlayerIndex ?? 0
                                iconsPath: popup.iconsPath
                                onPlayerChanged: index => {
                                    popup._fadeTransition = true
                                    if (popup.widgetRef) popup.widgetRef.activePlayerIndex = index
                                }
                            }

                            Item {
                                width: parent.width
                                implicitHeight: artBlock.height + titleBlock.height + 14

                                Item {
                                    id: artBlock
                                    width: parent.width; height: parent.width
                                    clip: true
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle { width: artBlock.width; height: artBlock.height; radius: 10 }
                                    }

                                    Image {
                                        id: artOut
                                        width: parent.width; height: parent.height
                                        fillMode: Image.PreserveAspectFit
                                        cache: true; opacity: 0
                                        sourceSize.width: 300; sourceSize.height: 300
                                    }

                                    Image {
                                        id: artIn
                                        width: parent.width; height: parent.height
                                        source: popup.displayArtUrl
                                        fillMode: Image.PreserveAspectFit
                                        cache: true; asynchronous: true
                                        sourceSize.width: 300; sourceSize.height: 300

                                        onSourceChanged: {
                                            if (popup._fadeTransition) {
                                                popup._fadeTransition = false
                                                artOut.source = artIn.source
                                                artOut.opacity = 0
                                                artIn.x = 0; artIn.opacity = 0
                                                fadeInAnim.restart()
                                            } else {
                                                artOut.source = artIn.source
                                                artOut.x = 0; artOut.opacity = 1
                                                artIn.x = popup._slideBackward ? -artIn.width : artIn.width
                                                slideAnim.from = popup._slideBackward ? -artIn.width : artIn.width
                                                slideAnim.to = 0
                                                slideOutAnim.from = 0
                                                slideOutAnim.to = popup._slideBackward ? artOut.width : -artOut.width
                                                slideAnim.restart(); slideOutAnim.restart()
                                            }
                                        }

                                        NumberAnimation on x {
                                            id: slideAnim
                                            from: artIn.width; to: 0; duration: 280
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent; radius: 10
                                        color: Qt.rgba(1, 1, 1, 0.05)
                                        visible: popup.displayArtUrl === "" || artIn.status === Image.Error
                                        Text {
                                            anchors.centerIn: parent
                                            text: "\u266A"
                                            font.pixelSize: 48
                                            color: Qt.rgba(1, 1, 1, 0.2)
                                        }
                                    }

                                    NumberAnimation {
                                        id: slideOutAnim
                                        target: artOut; property: "x"
                                        from: 0; to: -artOut.width; duration: 280
                                        easing.type: Easing.OutCubic
                                        onStopped: artOut.opacity = 0
                                    }

                                    SequentialAnimation {
                                        id: fadeInAnim
                                        NumberAnimation { target: artIn; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                                        ScriptAction { script: artOut.opacity = 0 }
                                    }
                                }

                                Column {
                                    id: titleBlock
                                    width: parent.width; spacing: 3
                                    anchors.top: artBlock.bottom; anchors.topMargin: 14

                                    Text {
                                        width: parent.width
                                        text: popup.trackTitle || "No title"
                                        color: "#ffffff"; font.pixelSize: 14; font.weight: Font.Medium
                                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                    }
                                    Text {
                                        width: parent.width; text: popup.trackAlbum
                                        color: Qt.rgba(1, 1, 1, 0.65); font.pixelSize: 11
                                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                        visible: text !== ""
                                    }
                                    Text {
                                        width: parent.width; text: popup.trackArtist
                                        color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 11
                                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                        visible: text !== ""
                                    }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 14

                                MusicSvgButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 28
                                    iconPath: popup.iconsPath + "repeat-once.svg"
                                    toggled: popup.repeatOnceActive
                                    btnEnabled: popup.repeatOnceSupported && popup.player !== null
                                    onClicked: {
                                        if (!popup.player?.loopSupported) return
                                        popup.player.loopState = popup.repeatOnceActive
                                            ? MprisLoopState.None : MprisLoopState.Track
                                    }
                                }
                                MusicSvgButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 28
                                    iconPath: popup.iconsPath + "rewind.svg"
                                    btnEnabled: popup.player?.canGoPrevious ?? false
                                    onClicked: {
                                        popup._slideBackward = true
                                        popup.player?.previous()
                                    }
                                }
                                MusicSvgButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 48
                                    iconPath: popup.playing
                                        ? popup.iconsPath + "pause.svg"
                                        : popup.iconsPath + "play.svg"
                                    btnEnabled: popup.player?.canTogglePlaying ?? false
                                    onClicked: popup.player?.togglePlaying()
                                }
                                MusicSvgButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 28
                                    iconPath: popup.iconsPath + "rewind.svg"
                                    iconRot: 180
                                    btnEnabled: popup.player?.canGoNext ?? false
                                    onClicked: {
                                        popup._slideBackward = false
                                        popup.player?.next()
                                    }
                                }
                                MusicSvgButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    size: 28
                                    iconPath: popup.iconsPath + "volume.svg"
                                    toggled: popup.volumeOpen
                                    btnEnabled: popup.volumeSupported && popup.player !== null
                                    visible: popup.volumeSupported
                                    onClicked: {
                                        popup.volumeOpen = !popup.volumeOpen
                                        Qt.callLater(popup.reposition)
                                    }
                                }
                            }

                            SeekBar {
                                id: seekBar
                                width: parent.width
                                player: popup.player
                                playing: popup.playing
                                visible: popup.player !== null && popup.lengthValid
                                progress: popup.progress
                                positionSecs: popup.positionSecs
                                lengthSecs: popup.lengthSecs
                            }
                        }
                    }
                }
            }

            Item {
                width: volumeFade.width
                height: popupRow.height

                MusicFadePanel {
                    id: volumeFade
                    anchors.verticalCenter: parent.verticalCenter
                    panelWidth: popup.volumePanelWidth
                    height: volumePanel.implicitHeight
                    shown: popup.volumeOpen && popup.volumeSupported

                    MusicVolumePanel {
                        id: volumePanel
                        player: popup.player
                        artUrl: popup.displayArtUrl
                    }
                }
            }
        }
    }
}
