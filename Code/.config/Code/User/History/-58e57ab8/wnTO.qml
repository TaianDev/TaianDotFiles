import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris

PopupWindow {
    id: popup

    required property var widgetRef
    required property var parentWindow

    visible: widgetRef?.popupOpen ?? false
    color:   "transparent"
    width:   300
    height:  contentCol.implicitHeight + 48

    anchor.window: parentWindow
    anchor.rect: Qt.rect(
        widgetRef.mapToItem(null, 0, 0).x + widgetRef.width - popup.width,
        parentWindow.height + 0,
        popup.width,
        popup.height
    )

    onVisibleChanged: {
        if (!visible && widgetRef) widgetRef.popupOpen = false
        if (visible) bubbleAnim.restart()
    }

    // ── Datos del reproductor ────────────────────────────────
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
    function iconExists(name) {
        if (!name || name === "") return false
        return Quickshell.iconPath(name, "") !== ""
    }

    function playerIcon(mprisPlayer) {
        if (!mprisPlayer) return ""
        const playerName = mprisPlayer.playerName ?? ""
        const desktopId  = mprisPlayer.desktopEntry ?? ""
        const identity   = mprisPlayer.identity ?? ""

        // 1. desktopEntry oficial
        if (desktopId !== "") {
            const entry = DesktopEntries.byId(desktopId)
            if (entry && iconExists(entry.icon))
                return Quickshell.iconPath(entry.icon, "")
            if (iconExists(desktopId))
                return Quickshell.iconPath(desktopId, "")
            if (iconExists(desktopId.toLowerCase()))
                return Quickshell.iconPath(desktopId.toLowerCase(), "")
        }
        // 2. playerName directo
        if (playerName !== "") {
            if (iconExists(playerName))
                return Quickshell.iconPath(playerName, "")
            if (iconExists(playerName.toLowerCase()))
                return Quickshell.iconPath(playerName.toLowerCase(), "")
        }
        // 3. identity lowercase
        if (identity !== "") {
            const id = identity.toLowerCase()
            if (iconExists(id)) return Quickshell.iconPath(id, "")
        }
        // 4. heuristic
        const heuristic = DesktopEntries.heuristicLookup(
            desktopId || playerName || identity)
        if (heuristic && iconExists(heuristic.icon))
            return Quickshell.iconPath(heuristic.icon, "")

        return ""
    }

    // ── Botón SVG ─────────────────────────────────────────────
    component SvgBtn: Item {
        id: btn
        property int    size:       24
        property string iconPath:   ""
        property int    iconRot:    0
        property bool   btnEnabled: true
        signal clicked()

        width: size; height: size
        opacity: !btnEnabled ? 0.3 : (ma.containsMouse ? 0.6 : 1.0)
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Image {
            anchors.centerIn: parent
            width: btn.size * 0.78; height: btn.size * 0.78
            source: btn.iconPath
            sourceSize.width: width; sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            rotation: btn.iconRot
            cache: true; asynchronous: true
            layer.enabled: true
            layer.effect: ColorOverlay { color: "#ffffff" }
        }
        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true
            cursorShape: btn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.btnEnabled) btn.clicked()
        }
    }

    // ══════════════════════════════════════════════════════════
    // BURBUJA
    // ══════════════════════════════════════════════════════════
    Item {
        id: bubbleRoot
        anchors.fill: parent
        opacity: 0; scale: 0.88
        transformOrigin: Item.TopRight

        ParallelAnimation {
            id: bubbleAnim
            NumberAnimation {
                target: bubbleRoot; property: "opacity"
                from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: bubbleRoot; property: "scale"
                from: 0.88; to: 1; duration: 280
                easing.type: Easing.OutBack; easing.overshoot: 0.6
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color:  Qt.rgba(0.08, 0.08, 0.08, 0.92)
            border.width: 0.5; border.color: Qt.rgba(1,1,1,0.12)
            clip: true

            // Fondo blureado
            Item {
                anchors.fill: parent
                visible: popup.displayArtUrl !== ""

                Image {
                    id: popupBg
                    anchors.centerIn: parent
                    source: popup.displayArtUrl
                    width: parent.width + 60; height: parent.height + 60
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true
                    sourceSize.width: 200; sourceSize.height: 200

                    Behavior on source {
                        SequentialAnimation {
                            NumberAnimation { target: popupBg; property: "opacity"; to: 0; duration: 150 }
                            PropertyAction  {}
                            NumberAnimation { target: popupBg; property: "opacity"; to: 1; duration: 250 }
                        }
                    }
                }
                FastBlur { anchors.fill: popupBg; source: popupBg; radius: 60 }
                Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.68) }
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: popup.width; height: popup.height; radius: 16 }
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
                                anchors { fill: parent; margins: 6 }
                                source: playerBtn.iconSrc
                                fillMode: Image.PreserveAspectFit
                                cache: true; asynchronous: true
                                visible: playerBtn.iconSrc !== "" && status === Image.Ready
                            }
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.identity ?? "?")[0].toUpperCase()
                                color: "#ffffff"
                                font.pixelSize: 14; font.weight: Font.Medium
                                visible: playerBtn.iconSrc === ""
                                    || parent.children[0].status !== Image.Ready
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (popup.widgetRef) popup.widgetRef.activePlayerIndex = index
                            }
                        }
                    }
                }

                // ── Carátula con animación slide ──────────────
                Item {
                    width: parent.width; height: parent.width
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

                // ── Título, álbum, artista ────────────────────
                Column {
                    width: parent.width; spacing: 3
                    Text {
                        width: parent.width
                        text: popup.trackTitle || "Sin título"
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

                // ── Controles ─────────────────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28; iconPath: popup.iconsPath + "rewind.svg"
                        btnEnabled: popup.player?.canGoPrevious ?? false
                        onClicked: popup.player?.previous()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 48
                        iconPath: popup.playing
                            ? popup.iconsPath + "pause.svg"
                            : popup.iconsPath + "play.svg"
                        btnEnabled: popup.player?.canTogglePlaying ?? false
                        onClicked: popup.player?.togglePlaying()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28; iconPath: popup.iconsPath + "rewind.svg"
                        iconRot: 180
                        btnEnabled: popup.player?.canGoNext ?? false
                        onClicked: popup.player?.next()
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
