import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris
import "../../core"
import "../../services"
import "../shell"
import ".."

PopupWindow {
    id: popup

    required property var widgetRef
    required property var parentWindow

    readonly property bool open: widgetRef?.popupOpen ?? false

    grabFocus: open

    readonly property int mainWidth: 300
    readonly property int volumePanelWidth: 52
    readonly property int volumeGap: 8
    readonly property bool volumeSupported: popup.player?.volumeSupported ?? false

    property bool volumeOpen: false

    visible: open || shell.exitRunning || volumeFade.shown || volumeFade.exitRunning
    color:   "transparent"
    implicitWidth: popup.mainWidth
                     + (popup.volumeOpen && popup.volumeSupported
                        ? popup.volumeGap + popup.volumePanelWidth : 0)
    implicitHeight: contentCol.implicitHeight + 48

    function reposition() {
        if (!widgetRef || !parentWindow)
            return
        const totalW = Math.max(popup.mainWidth, implicitWidth)
        const h = Math.max(1, implicitHeight)
        const pos = widgetRef.mapToItem(parentWindow.contentItem, 0, widgetRef.height)
        const ax = pos.x + widgetRef.width / 2 - popup.mainWidth / 2
        anchor.window = parentWindow
        anchor.rect = Qt.rect(ax, pos.y + 8, totalW, h)
        anchor.updateAnchor()
    }

    onOpenChanged: {
        if (open) {
            reposition()
            shell.active = true
        } else {
            shell.active = false
            popup.volumeOpen = false
        }
    }
    readonly property var    player:      widgetRef?.player      ?? null
    readonly property bool   playing:     widgetRef?.playing     ?? false
    readonly property string trackTitle:  widgetRef?.trackTitle  ?? ""
    readonly property string trackArtist: widgetRef?.trackArtist ?? ""
    readonly property string trackAlbum:  player?.trackAlbum     ?? ""
    readonly property string iconsPath:   widgetRef?.iconsPath   ?? ""
    readonly property var    playerList:  widgetRef?.playerList  ?? []

    // Carátula: viene del caché global en MusicWidget, siempre actualizada
    readonly property string stableArtUrl: widgetRef?.stableArtUrl ?? ""

    // Carátula del player seleccionado en el popup (puede diferir del activo en barra)
    readonly property string selectedPkey: {
        const p = playerList.length > 0
            ? playerList[widgetRef?.activePlayerIndex ?? 0]
            : null
        return p?.playerName ?? p?.identity ?? "unknown"
    }
    readonly property string selectedArtUrl: widgetRef?.artCache?.[selectedPkey] ?? ""

    // La carátula que mostramos es la del player seleccionado en el popup
    readonly property string displayArtUrl: selectedArtUrl !== ""
        ? selectedArtUrl : stableArtUrl

    readonly property bool repeatOnceSupported: popup.player?.loopSupported ?? false
    readonly property bool repeatOnceActive: popup.player?.loopState === MprisLoopState.Track

    onVisibleChanged: {
        if (visible) {
            reposition()
        } else if (popup.open && !shell.exitRunning && !volumeFade.shown && !volumeFade.exitRunning) {
            widgetRef.popupOpen = false
        }
    }

    onVolumeOpenChanged: Qt.callLater(reposition)
    onImplicitWidthChanged: Qt.callLater(reposition)

    // ── Progreso y tiempo ────────────────────────────────────
    readonly property bool lengthValid:   (player?.length ?? 0) > 0
    readonly property bool positionValid: player?.positionSupported ?? false
    readonly property real positionSecs:  player?.position ?? 0
    readonly property real lengthSecs:    player?.length   ?? 0
    readonly property real progress: (lengthValid && positionValid)
        ? Math.min(1, positionSecs / lengthSecs) : 0

    Timer {
        running: popup.playing && popup.visible && popup.positionValid
        interval: 250; repeat: true
        onTriggered: if (popup.player) popup.player.positionChanged()
    }

    function formatTime(secs) {
        if (!secs || secs <= 0) return "0:00"
        const s = Math.floor(secs) % 60
        const m = Math.floor(secs / 60)
        return `${m}:${s.toString().padStart(2, "0")}`
    }

    // ── Iconos de reproductores ───────────────────────────────
    function resolveIconPath(names) {
        for (let i = 0; i < names.length; i++) {
            const name = names[i]
            if (!name || name === "" || name === "zen" || name.includes(" "))
                continue

            if (Quickshell.hasThemeIcon(name)) {
                const path = Quickshell.iconPath(name)
                if (path !== "")
                    return path
            }

            const path = Quickshell.iconPath(name)
            if (path !== "")
                return path
        }
        return ""
    }

    function playerIconCandidates(mprisPlayer) {
        const out = []
        const seen = {}

        function add(name) {
            if (!name || seen[name])
                return
            seen[name] = true
            out.push(name)
        }

        const playerName = mprisPlayer.playerName ?? ""
        const desktopId  = mprisPlayer.desktopEntry ?? ""
        const identity   = mprisPlayer.identity ?? ""
        const baseName   = playerName.split(".")[0]

        const aliases = {
            "zen":           ["zen-browser", "io.github.zen_browser.zen"],
            "firefox":       ["firefox"],
            "spotify":       ["spotify"],
            "vlc":           ["vlc"],
            "mpv":           ["mpv"],
            "chromium":      ["chromium", "google-chrome"],
            "google-chrome": ["google-chrome"],
            "tidal":         ["tidal", "com.tidal.Tidal"],
        }

        const aliasKey = baseName.toLowerCase()

        for (const id of [desktopId, baseName]) {
            if (!id)
                continue
            const entry = DesktopEntries.byId(id)
            if (entry?.icon)
                add(entry.icon)
            if (id.toLowerCase() !== aliasKey || !aliases[aliasKey])
                add(id)
        }

        if (aliases[aliasKey]) {
            for (let i = 0; i < aliases[aliasKey].length; i++)
                add(aliases[aliasKey][i])
        } else {
            add(playerName)
            add(baseName)
            add(baseName.toLowerCase())
        }

        if (identity !== "" && !aliases[aliasKey]) {
            add(identity.replace(/\s+/g, "-").toLowerCase())
            add(identity.replace(/\s+/g, "").toLowerCase())
        }

        if (!aliases[aliasKey]) {
            const heuristic = DesktopEntries.heuristicLookup(
                desktopId || playerName || identity)
            if (heuristic?.icon && heuristic.icon !== aliasKey)
                add(heuristic.icon)
        }

        return out
    }

    function playerIcon(mprisPlayer) {
        if (!mprisPlayer)
            return ""
        return resolveIconPath(playerIconCandidates(mprisPlayer))
    }

    // ══════════════════════════════════════════════════════════
    // BURBUJA + PANEL DE VOLUMEN (caja lateral)
    // ══════════════════════════════════════════════════════════
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
        originH: Item.Center
        originV: Item.Top

        Item {
            id: bubbleContent
            anchors.fill: parent

            // Fondo: carátula difuminada (máscara redondeada — clip no funciona con FastBlur)
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
                        width: parent.width + 60
                        height: parent.height + 60
                        fillMode: Image.PreserveAspectCrop
                        cache: true
                        asynchronous: true
                        sourceSize: Qt.size(200, 200)

                        Behavior on source {
                            SequentialAnimation {
                                NumberAnimation { target: popupBg; property: "opacity"; to: 0; duration: 150 }
                                PropertyAction { }
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
                    color: Theme.alpha(Theme.background, 0.92)
                }
            }

            Column {
                id: contentCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
                spacing: 14

                // ── Selector de players ───────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    visible: popup.playerList.length > 1

                    Repeater {
                        model: popup.playerList

                        Rectangle {
                            id: playerBtn
                            width: 36; height: 36; radius: 10
                            color: index === (popup.widgetRef?.activePlayerIndex ?? 0)
                                ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.06)
                            border.width: index === (popup.widgetRef?.activePlayerIndex ?? 0) ? 1 : 0
                            border.color: Qt.rgba(1,1,1,0.35)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            property string iconSrc: popup.playerIcon(modelData)

                            Image {
                                id: playerIconImg
                                anchors { fill: parent; margins: 6 }
                                source: playerBtn.iconSrc
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                                cache: true
                                asynchronous: true
                                visible: playerBtn.iconSrc !== "" && status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.identity ?? "?")[0].toUpperCase()
                                color: "#ffffff"
                                font.pixelSize: 14; font.weight: Font.Medium
                                visible: playerBtn.iconSrc === ""
                                    || playerIconImg.status === Image.Error
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (popup.widgetRef) popup.widgetRef.activePlayerIndex = index
                            }
                        }
                    }
                }

                // ── Carátula y metadatos ──────────────────────
                Item {
                    width: parent.width
                    implicitHeight: artBlock.height + titleBlock.height + 14

                    // ── Carátula con animación slide ──────────
                    Item {
                        id: artBlock
                        width: parent.width
                        height: parent.width
                        clip: true

                            Image {
                                id: artOut
                                width: parent.width; height: parent.height
                                fillMode: Image.PreserveAspectFit
                                cache: true; opacity: 0
                                sourceSize.width: 300; sourceSize.height: 300
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle { width: artOut.width; height: artOut.height; radius: 10 }
                                }
                            }

                            Image {
                                id: artIn
                                width: parent.width; height: parent.height
                                source: popup.displayArtUrl
                                fillMode: Image.PreserveAspectFit
                                cache: true; asynchronous: true
                                sourceSize.width: 300; sourceSize.height: 300
                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle { width: artIn.width; height: artIn.height; radius: 10 }
                                }

                                onSourceChanged: {
                                    artOut.source  = artIn.source
                                    artOut.x = 0; artOut.opacity = 1
                                    artIn.x  = artIn.width
                                    slideIn.restart(); slideOut.restart()
                                }

                                NumberAnimation on x {
                                    id: slideIn
                                    from: artIn.width; to: 0
                                    duration: 280; easing.type: Easing.OutCubic
                                }
                            }

                            Rectangle {
                                anchors.fill: parent; radius: 10
                                color: Qt.rgba(1,1,1,0.05)
                                visible: popup.displayArtUrl === "" || artIn.status === Image.Error
                                Text {
                                    anchors.centerIn: parent; text: "♪"
                                    font.pixelSize: 48; color: Qt.rgba(1,1,1,0.2)
                                }
                            }

                            NumberAnimation {
                                id: slideOut
                                target: artOut; property: "x"
                                from: 0; to: -artOut.width
                                duration: 280; easing.type: Easing.OutCubic
                                onStopped: artOut.opacity = 0
                            }
                        }

                        // ── Título, álbum, artista ────────────────
                        Column {
                            id: titleBlock
                            width: parent.width
                            spacing: 3
                            anchors.top: artBlock.bottom
                            anchors.topMargin: 14

                            Text {
                                width: parent.width
                                text: popup.trackTitle || "No title"
                                color: "#ffffff"; font.pixelSize: 14; font.weight: Font.Medium
                                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                width: parent.width; text: popup.trackAlbum
                                color: Qt.rgba(1,1,1,0.65); font.pixelSize: 11
                                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                visible: text !== ""
                            }
                            Text {
                                width: parent.width; text: popup.trackArtist
                                color: Qt.rgba(1,1,1,0.5); font.pixelSize: 11
                                elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                                visible: text !== ""
                            }
                        }
                    }

                // ── Controles ─────────────────────────────────
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
                            if (!popup.player?.loopSupported)
                                return
                            popup.player.loopState = popup.repeatOnceActive
                                ? MprisLoopState.None
                                : MprisLoopState.Track
                        }
                    }

                    MusicSvgButton {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconPath: popup.iconsPath + "rewind.svg"
                        btnEnabled: popup.player?.canGoPrevious ?? false
                        onClicked: popup.player?.previous()
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
                        onClicked: popup.player?.next()
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

                // ── Barra de progreso ─────────────────────────
                Column {
                    width: parent.width; spacing: 4
                    visible: popup.player !== null && popup.lengthValid

                    Item {
                        width: parent.width; height: 14
                        Rectangle {
                            id: track
                            width: parent.width; height: 4; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(1,1,1,0.18)
                            Rectangle {
                                id: fill
                                width: track.width * popup.progress
                                height: parent.height; radius: 2; color: "#ffffff"
                            }
                            Rectangle {
                                width: 10; height: 10; radius: 5; color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, fill.width - 5)
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (!popup.player?.canSeek) return
                                popup.player.position = (mouse.x / width) * popup.player.length
                            }
                        }
                    }

                    Item {
                        width: parent.width; height: 14
                        Text {
                            anchors.left: parent.left
                            text: popup.formatTime(popup.positionSecs)
                            color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10
                        }
                        Text {
                            anchors.right: parent.right
                            text: popup.formatTime(popup.lengthSecs)
                            color: Qt.rgba(1,1,1,0.5); font.pixelSize: 10
                        }
                    }
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
