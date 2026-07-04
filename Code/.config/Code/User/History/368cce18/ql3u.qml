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
        parentWindow.height + 8,
        popup.width,
        popup.height
    )

    onVisibleChanged: {
        if (!visible && widgetRef) widgetRef.popupOpen = false
        if (visible) bubbleAnim.restart()
    }

    // ── Shortcuts ─────────────────────────────────────────────
    readonly property var    player:      widgetRef?.player      ?? null
    readonly property string artUrl:      widgetRef?.artUrl      ?? ""
    readonly property bool   playing:     widgetRef?.playing     ?? false
    readonly property string trackTitle:  widgetRef?.trackTitle  ?? ""
    readonly property string trackArtist: widgetRef?.trackArtist ?? ""
    readonly property string trackAlbum:  widgetRef?.player?.trackAlbum ?? ""
    readonly property string iconsPath:   widgetRef?.iconsPath   ?? ""
    readonly property var    playerList:  widgetRef?.playerList  ?? []

    // Firefox bug: a veces length = 0 o position no avanza
    // Detectamos si el player soporta duración real
    readonly property bool lengthValid: (player?.length ?? 0) > 0
    readonly property bool positionValid: player?.positionSupported ?? false

    // position y length en segundos (tal como los expone Quickshell)
    readonly property real positionSecs: player?.position ?? 0
    readonly property real lengthSecs:   player?.length   ?? 0
    readonly property real progress: (lengthValid && positionValid)
        ? Math.min(1, positionSecs / lengthSecs) : 0

    // Timer para forzar actualización reactiva de position
    Timer {
        running: popup.playing && popup.visible && popup.positionValid
        interval: 1000
        repeat: true
        onTriggered: if (popup.player) popup.player.positionChanged()
    }

    function formatTime(secs) {
        if (!secs || secs <= 0) return "0:00"
        const s = Math.floor(secs) % 60
        const m = Math.floor(secs / 60)
        return `${m}:${s.toString().padStart(2, "0")}`
    }

    // Icono del player — manejo robusto para Firefox y otros
    function playerIcon(mprisPlayer) {
        if (!mprisPlayer) return ""
        // Intentar por desktopEntry
        const desktopId = mprisPlayer.desktopEntry ?? ""
        if (desktopId !== "") {
            const entry = DesktopEntries.byId(desktopId)
            if (entry) {
                const path = Quickshell.iconPath(entry.icon, "")
                if (path !== "") return path
            }
            // Intentar directamente el desktopEntry como nombre de icono
            const direct = Quickshell.iconPath(desktopId, "")
            if (direct !== "") return direct
            // lowercase
            const lower = Quickshell.iconPath(desktopId.toLowerCase(), "")
            if (lower !== "") return lower
        }
        // Intentar por identity (nombre del player ej: "Firefox")
        const identity = mprisPlayer.identity ?? ""
        if (identity !== "") {
            const byName = Quickshell.iconPath(identity.toLowerCase(), "")
            if (byName !== "") return byName
        }
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
            width:  btn.size * 0.78; height: btn.size * 0.78
            source: btn.iconPath
            sourceSize.width: width; sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            rotation: btn.iconRot
            cache: false
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
    // BURBUJA — animación de emerge desde abajo
    // ══════════════════════════════════════════════════════════
    Item {
        id: bubbleRoot
        anchors.fill: parent
        opacity: 0
        scale: 0.88
        transformOrigin: Item.TopRight

        // Animación de entrada tipo "burbuja que emerge"
        ParallelAnimation {
            id: bubbleAnim
            NumberAnimation {
                target: bubbleRoot; property: "opacity"
                from: 0; to: 1
                duration: 220; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: bubbleRoot; property: "scale"
                from: 0.88; to: 1
                duration: 280; easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 16
            color:  Qt.rgba(0.08, 0.08, 0.08, 0.92)
            border.width: 0.5
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            // Fondo arte blureado
            Item {
                anchors.fill: parent
                visible: popup.artUrl !== ""

                Image {
                    id: popupBg
                    anchors.centerIn: parent
                    source: popup.artUrl
                    width:  parent.width  + 60
                    height: parent.height + 60
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    sourceSize.width: 400
                    sourceSize.height: 400

                    Behavior on source {
                        SequentialAnimation {
                            NumberAnimation { target: popupBg; property: "opacity"; to: 0; duration: 160 }
                            PropertyAction  {}
                            NumberAnimation { target: popupBg; property: "opacity"; to: 1; duration: 260 }
                        }
                    }
                }
                FastBlur { anchors.fill: popupBg; source: popupBg; radius: 90 }
                Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, 0.68) }
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: popup.width; height: popup.height; radius: 16
                }
            }

            Column {
                id: contentCol
                anchors {
                    top: parent.top; left: parent.left; right: parent.right
                    margins: 20
                }
                spacing: 14

                // ── Selector de players ───────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    visible: popup.playerList.length > 1

                    Repeater {
                        model: popup.playerList
                        Text {
                            text: modelData.desktopEntry + " | " + modelData.identity
                            color: "yellow"
                            font.pixelSize: 9
                        }
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
                                cache: false
                                asynchronous: true
                                visible: playerBtn.iconSrc !== "" && status === Image.Ready
                            }

                            // Fallback: inicial del nombre
                            Text {
                                anchors.centerIn: parent
                                text: (modelData.identity ?? "?")[0].toUpperCase()
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.weight: Font.Medium
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

                // ── Arte con animación slide ──────────────────
                Item {
                    width: parent.width
                    height: parent.width
                    clip: true

                    Image {
                        id: artOut
                        width: parent.width; height: parent.height
                        fillMode: Image.PreserveAspectFit
                        cache: false; opacity: 0
                        sourceSize.width: 300; sourceSize.height: 300
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: artOut.width; height: artOut.height; radius: 10 }
                        }
                    }

                    Image {
                        id: artIn
                        width: parent.width; height: parent.height
                        source: popup.artUrl
                        fillMode: Image.PreserveAspectFit
                        cache: false; asynchronous: true
                        sourceSize.width: 300; sourceSize.height: 300
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: artIn.width; height: artIn.height; radius: 10 }
                        }

                        onSourceChanged: {
                            artOut.source  = artIn.source
                            artOut.x = 0; artOut.opacity = 1
                            artIn.x  = artIn.width
                            slideIn.restart()
                            slideOut.restart()
                        }

                        NumberAnimation on x {
                            id: slideIn
                            from: artIn.width; to: 0
                            duration: 320; easing.type: Easing.OutCubic
                        }
                    }

                    // Placeholder cuando no hay arte (Firefox sin portada)
                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: Qt.rgba(1,1,1,0.05)
                        visible: popup.artUrl === "" || artIn.status === Image.Error

                        Text {
                            anchors.centerIn: parent
                            text: "♪"
                            font.pixelSize: 48
                            color: Qt.rgba(1,1,1,0.2)
                        }
                    }

                    NumberAnimation {
                        id: slideOut
                        target: artOut; property: "x"
                        from: 0; to: -artOut.width
                        duration: 320; easing.type: Easing.OutCubic
                        onStopped: artOut.opacity = 0
                    }
                }

                // ── Título, álbum, artista ────────────────────
                Column {
                    width: parent.width
                    spacing: 3

                    Text {
                        width: parent.width
                        text: popup.trackTitle || "Sin título"
                        color: "#ffffff"
                        font.pixelSize: 14; font.weight: Font.Medium
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: popup.trackAlbum
                        color: Qt.rgba(1,1,1,0.65)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                    Text {
                        width: parent.width
                        text: popup.trackArtist
                        color: Qt.rgba(1,1,1,0.5)
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }

                // ── Controles ─────────────────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconPath: popup.iconsPath + "rewind.svg"
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
                        size: 28
                        iconPath: popup.iconsPath + "rewind.svg"
                        iconRot: 180
                        btnEnabled: popup.player?.canGoNext ?? false
                        onClicked: popup.player?.next()
                    }
                }

                // ── Barra de progreso ─────────────────────────
                Column {
                    width: parent.width
                    spacing: 4
                    // Ocultar si Firefox no reporta duración
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
                                height: parent.height; radius: 2
                                color: "#ffffff"
                            }
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, fill.width - 5)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
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
