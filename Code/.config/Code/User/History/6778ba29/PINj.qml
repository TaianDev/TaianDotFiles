import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

// Uso en Bar.qml:
//   MusicWidget { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: 20 }

Item {
    id: root

    // ── Tamaños ──────────────────────────────────────────────
    property int capsuleHeight: 28
    property int buttonSize:    20
    property int popupWidth:    320
    property int popupHeight:   400

    implicitHeight: capsuleHeight
    implicitWidth:  pillRow.implicitWidth + 24

    // ── Player activo ─────────────────────────────────────────
    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length)
            activePlayerIndex = 0
    }

    property var player:  playerList.length > 0 ? playerList[activePlayerIndex] : null
    property string trackTitle:  player?.trackTitle  ?? ""
    property string trackArtist: player?.trackArtist ?? ""
    property string artUrl:      player?.trackArtUrl  ?? ""
    property bool   playing:     player?.playbackState === MprisPlaybackState.Playing

    // ── Popup visible ─────────────────────────────────────────
    property bool popupOpen: false

    // ══════════════════════════════════════════════════════════
    // CÁPSULA PRINCIPAL
    // ══════════════════════════════════════════════════════════
    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: capsuleHeight / 2
        color: Qt.rgba(1, 1, 1, 0.08)
        border.width: 0.5
        border.color: Qt.rgba(1, 1, 1, 0.12)
        clip: true

        // Arte de fondo con blur
        Item {
            anchors.fill: parent
            visible: root.artUrl !== ""

            Image {
                id: artBg
                anchors.centerIn: parent
                source: root.artUrl
                width:  parent.width  + 20
                height: parent.height + 20
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                Behavior on source { PropertyAnimation { duration: 0 } }
            }

            FastBlur {
                anchors.fill: artBg
                source: artBg
                radius: 40
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.6)
            }
        }

        // Contenido de la cápsula
        RowLayout {
            id: pillRow
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 6

            // Miniatura del álbum
            Rectangle {
                width: 20; height: 20
                radius: 4
                color: Qt.rgba(1,1,1,0.1)
                visible: root.artUrl !== ""
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                }

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: 20; height: 20; radius: 4 }
                }
            }

            // Título (animado si es largo)
            Item {
                Layout.preferredWidth: 100
                height: capsule.height
                visible: root.player !== null
                clip: true

                Text {
                    id: titleText
                    text: root.trackTitle !== "" ? root.trackTitle : "Sin título"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter

                    NumberAnimation on x {
                        running: titleText.implicitWidth > 100
                        loops:   Animation.Infinite
                        from:    0
                        to:      -(titleText.implicitWidth + 20)
                        duration: titleText.implicitWidth * 30
                    }
                }
            }

            Text {
                visible: root.player === null
                text: "Sin reproducción"
                color: Qt.rgba(1,1,1,0.4)
                font.pixelSize: 11
            }

            // Botón anterior
            MusicBtn {
                size: root.buttonSize
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player?.previous()
                label: "⏮"
            }

            // Play / Pause
            MusicBtn {
                size: root.buttonSize + 2
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player?.togglePlaying()
                label: root.playing ? "⏸" : "▶"
            }

            // Botón siguiente
            MusicBtn {
                size: root.buttonSize
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player?.next()
                label: "⏭"
            }

            // Botón popup
            MusicBtn {
                size: root.buttonSize
                label: "⋯"
                highlight: root.popupOpen
                onClicked: root.popupOpen = !root.popupOpen
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: root.popupOpen = !root.popupOpen
        }
    }

    // Scroll para volumen
    WheelHandler {
        onWheel: event => {
            if (!root.player) return
            const delta = event.angleDelta.y / 120 * 0.05
            root.player.volume = Math.max(0, Math.min(1, root.player.volume + delta))
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // ══════════════════════════════════════════════════════════
    // POPUP
    // ══════════════════════════════════════════════════════════
    PopupWindow {
        id: popup
        visible: root.popupOpen
        color: "transparent"

        implicitWidth:  root.popupWidth
        implicitHeight: root.popupHeight

        // Anclar bajo el widget, alineado a la derecha
        anchor {
            window: root.QsWindow.window
            rect: Qt.rect(
                root.x + root.width - root.popupWidth,
                root.y + root.height + 6,
                root.popupWidth,
                root.popupHeight
            )
        }

        onVisibleChanged: if (!visible) root.popupOpen = false

        // Fondo del popup
        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Qt.rgba(0.1, 0.1, 0.1, 0.92)
            border.width: 0.5
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            // Arte de fondo blureado para el popup
            Item {
                anchors.fill: parent
                visible: root.artUrl !== ""

                Image {
                    id: popupArtBg
                    anchors.centerIn: parent
                    source: root.artUrl
                    width:  parent.width  + 40
                    height: parent.height + 40
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true

                    Behavior on source {
                        SequentialAnimation {
                            NumberAnimation { target: popupArtBg; property: "opacity"; to: 0; duration: 200 }
                            PropertyAction  { target: popupArtBg; property: "source" }
                            NumberAnimation { target: popupArtBg; property: "opacity"; to: 1; duration: 300 }
                        }
                    }
                }

                FastBlur {
                    anchors.fill: popupArtBg
                    source: popupArtBg
                    radius: 80
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.72)
                }
            }

            // layer clip redondeado
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: root.popupWidth; height: root.popupHeight; radius: 14
                }
            }

            Column {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 12

                // ── Selector de players ───────────────────────
                Row {
                    spacing: 8
                    visible: root.playerList.length > 1

                    Repeater {
                        model: root.playerList

                        Rectangle {
                            width: 36; height: 36
                            radius: 8
                            color: index === root.activePlayerIndex
                                ? Qt.rgba(1,1,1,0.2)
                                : Qt.rgba(1,1,1,0.06)
                            border.width: index === root.activePlayerIndex ? 1 : 0
                            border.color: Qt.rgba(1,1,1,0.3)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent
                                anchors.margins: 6
                                source: {
                                    const entry = DesktopEntries.byId(modelData.desktopEntry ?? "")
                                    return entry ? Quickshell.iconPath(entry.icon, "") : ""
                                }
                                fillMode: Image.PreserveAspectFit
                                cache: false
                                asynchronous: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activePlayerIndex = index
                            }
                        }
                    }
                }

                // ── Arte del álbum ────────────────────────────
                Item {
                    width:  parent.width
                    height: parent.width

                    // Imagen saliente (animación al cambiar canción)
                    Image {
                        id: artPrev
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        opacity: 0
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artPrev.width; height: artPrev.height; radius: 10
                            }
                        }
                    }

                    // Imagen entrante
                    Image {
                        id: artCurrent
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true

                        onSourceChanged: {
                            artPrev.source  = artCurrent.source
                            artPrev.opacity = 1
                            artCurrentAnim.restart()
                            artPrevAnim.restart()
                        }

                        NumberAnimation {
                            id: artCurrentAnim
                            target: artCurrent; property: "x"
                            from: artCurrent.width; to: 0
                            duration: 350; easing.type: Easing.OutCubic
                        }

                        NumberAnimation {
                            id: artPrevAnim
                            target: artPrev; property: "x"
                            from: 0; to: -artPrev.width
                            duration: 350; easing.type: Easing.OutCubic
                            onStopped: artPrev.opacity = 0
                        }

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artCurrent.width; height: artCurrent.height; radius: 10
                            }
                        }
                    }
                }

                // ── Título y artista ──────────────────────────
                Column {
                    width: parent.width
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.trackTitle !== "" ? root.trackTitle : "Sin título"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: root.trackArtist
                        color: Qt.rgba(1,1,1,0.6)
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }

                // ── Barra de progreso ─────────────────────────
                Item {
                    width: parent.width
                    height: 4
                    visible: root.player !== null

                    // Actualizar posición cada segundo mientras reproduce
                    Timer {
                        running: root.playing && popup.visible
                        interval: 1000
                        repeat: true
                        onTriggered: progressBar.updateProgress()
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: Qt.rgba(1,1,1,0.2)

                        Rectangle {
                            id: progressBar
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                            radius: 2
                            color: "#b4a7f5"
                            width: 0

                            function updateProgress() {
                                if (!root.player || root.player.length <= 0) return
                                width = parent.width * (root.player.position / root.player.length)
                            }

                            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                        }
                    }

                    // Click para seek
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            if (!root.player?.canSeek) return
                            root.player.position = (mouse.x / width) * root.player.length
                            progressBar.updateProgress()
                        }
                    }
                }

                // Tiempo
                Row {
                    width: parent.width
                    visible: root.player !== null

                    Text {
                        text: root.player ? formatTime(root.player.position) : "0:00"
                        color: Qt.rgba(1,1,1,0.5)
                        font.pixelSize: 10
                    }

                    Item { width: parent.width - posLeft.implicitWidth - posRight.implicitWidth; height: 1
                        id: posLeft
                    }

                    Text {
                        id: posRight
                        text: root.player ? formatTime(root.player.length) : "0:00"
                        color: Qt.rgba(1,1,1,0.5)
                        font.pixelSize: 10
                    }
                }

                // ── Controles ─────────────────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    MusicBtn {
                        size: 36
                        label: "⏮"
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }

                    MusicBtn {
                        size: 48
                        label: root.playing ? "⏸" : "▶"
                        enabled: root.player?.canTogglePlaying ?? false
                        highlight: true
                        onClicked: root.player?.togglePlaying()
                    }

                    MusicBtn {
                        size: 36
                        label: "⏭"
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player?.next()
                    }
                }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const s = Math.floor(seconds) % 60
        const m = Math.floor(seconds / 60)
        return `${m}:${s.toString().padStart(2, "0")}`
    }

    // Componente interno de botón
    component MusicBtn: Rectangle {
        id: btn
        property int    size:      22
        property string label:     ""
        property bool   highlight: false
        signal clicked()

        width:  size
        height: size
        radius: size / 2
        color: highlight
            ? Qt.rgba(1,1,1,0.2)
            : (ma.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(0,0,0,0))

        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: btn.label
            font.pixelSize: btn.size * 0.5
            color: btn.enabled ? "#ffffff" : Qt.rgba(1,1,1,0.25)
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
