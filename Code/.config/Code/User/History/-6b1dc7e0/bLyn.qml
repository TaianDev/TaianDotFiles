import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

Item {
    id: root

    // ── Configuración ─────────────────────────────────────────
    property int capsuleHeight: 28
    property int buttonSize:    20
    property int popupWidth:    320
    property int popupHeight:   460

    // Ruta base a los iconos SVG — ajusta si cambia la ubicación
    property string iconsPath: Qt.resolvedUrl("../assets/icons/")

    implicitHeight: capsuleHeight
    implicitWidth:  root.player !== null ? pillRow.implicitWidth + 24 : 0
    visible:        root.player !== null

    // ── Estado del player ─────────────────────────────────────
    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length)
            activePlayerIndex = Math.max(0, playerList.length - 1)
    }

    readonly property var    player:      playerList.length > 0 ? playerList[activePlayerIndex] : null
    readonly property string trackTitle:  player?.trackTitle  ?? ""
    readonly property string trackAlbum:  player?.trackAlbum  ?? ""
    readonly property string trackArtist: player?.trackArtist ?? ""
    readonly property string artUrl:      player?.trackArtUrl ?? ""
    readonly property bool   playing:     player?.isPlaying   ?? false

    // Posición en segundos (Mpris usa microsegundos)
    readonly property real positionSecs: (player?.position ?? 0) / 1_000_000
    readonly property real lengthSecs:   (player?.length   ?? 0) / 1_000_000
    readonly property real progress:     lengthSecs > 0 ? Math.min(1, positionSecs / lengthSecs) : 0

    property bool popupOpen: false

    // ── Helpers ───────────────────────────────────────────────
    function formatTime(secs) {
        if (!secs || secs <= 0) return "0:00"
        const s = Math.floor(secs) % 60
        const m = Math.floor(secs / 60)
        return `${m}:${s.toString().padStart(2, "0")}`
    }

    // ══════════════════════════════════════════════════════════
    // COMPONENTE INTERNO: Botón SVG con overlay blanco
    // ══════════════════════════════════════════════════════════
    component SvgBtn: Item {
        id: btn
        property int    size:         24
        property string iconPath:     ""
        property int    iconRotation: 0
        property bool   btnEnabled:   true
        signal clicked()

        width:   size
        height:  size
        opacity: !btnEnabled ? 0.3 : (ma.containsMouse ? 0.65 : 1.0)
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Image {
            id: btnIcon
            anchors.centerIn: parent
            width:  parent.size * 0.78
            height: parent.size * 0.78
            source: btn.iconPath
            sourceSize.width:  width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            rotation: btn.iconRotation
            cache: false
            // layer necesario para que ColorOverlay funcione sobre SVG
            layer.enabled: true
            layer.effect: ColorOverlay {
                color: "#ffffff"
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.btnEnabled) btn.clicked()
        }
    }

    // ══════════════════════════════════════════════════════════
    // 1. CÁPSULA PRINCIPAL
    // ══════════════════════════════════════════════════════════
    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: capsuleHeight / 2
        color:  Qt.rgba(1, 1, 1, 0.08)
        border.width: 0.5
        border.color: Qt.rgba(1, 1, 1, 0.12)
        clip: true

        // Arte de fondo blureado
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
            }
            FastBlur {
                anchors.fill: artBg
                source: artBg
                radius: 40
            }
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.58)
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            // Miniatura circular
            Rectangle {
                width: 20; height: 20
                radius: 10
                color: "transparent"
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
                    maskSource: Rectangle { width: 20; height: 20; radius: 10 }
                }
            }

            // Controles
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                SvgBtn {
                    size: root.buttonSize
                    iconPath: root.iconsPath + "rewind.svg"
                    btnEnabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }
                SvgBtn {
                    size: root.buttonSize + 4
                    iconPath: root.playing
                        ? root.iconsPath + "pause.svg"
                        : root.iconsPath + "play.svg"
                    btnEnabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player?.togglePlaying()
                }
                SvgBtn {
                    size: root.buttonSize
                    iconPath: root.iconsPath + "rewind.svg"
                    iconRotation: 180
                    btnEnabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.popupOpen = !root.popupOpen
        }
    }

    // Scroll para volumen
    WheelHandler {
        onWheel: event => {
            if (!root.player) return
            const delta = event.angleDelta.y / 120 * 0.05
            root.player.volume = Math.max(0, Math.min(1, (root.player.volume ?? 0) + delta))
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    // ══════════════════════════════════════════════════════════
    // 2. POPUP
    // Usamos FloatingWindow anclado manualmente bajo la cápsula
    // ══════════════════════════════════════════════════════════
    FloatingWindow {
        id: popup
        visible: root.popupOpen
        color:   "transparent"
        width:   root.popupWidth
        height:  root.popupHeight

        // Cierra con Escape o click fuera
        onVisibleChanged: if (!visible) root.popupOpen = false

        Rectangle {
            anchors.fill: parent
            radius: 16
            color:  Qt.rgba(0.08, 0.08, 0.08, 0.88)
            border.width: 0.5
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            // Fondo blureado del popup
            Item {
                anchors.fill: parent
                visible: root.artUrl !== ""

                Image {
                    id: popupArtBg
                    anchors.centerIn: parent
                    source: root.artUrl
                    width:  parent.width  + 60
                    height: parent.height + 60
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true

                    Behavior on source {
                        SequentialAnimation {
                            NumberAnimation { target: popupArtBg; property: "opacity"; to: 0; duration: 180 }
                            PropertyAction  {}
                            NumberAnimation { target: popupArtBg; property: "opacity"; to: 1; duration: 280 }
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
                    color: Qt.rgba(0, 0, 0, 0.65)
                }
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: root.popupWidth; height: root.popupHeight; radius: 16
                }
            }

            Column {
                anchors {
                    fill: parent
                    margins: 20
                }
                spacing: 16

                // ── Selector de players ───────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    visible: root.playerList.length > 1

                    Repeater {
                        model: root.playerList

                        Rectangle {
                            width: 34; height: 34
                            radius: 8
                            color: index === root.activePlayerIndex
                                ? Qt.rgba(1,1,1,0.22)
                                : Qt.rgba(1,1,1,0.06)
                            border.width: index === root.activePlayerIndex ? 1 : 0
                            border.color: Qt.rgba(1,1,1,0.35)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors { fill: parent; margins: 6 }
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

                // ── Arte del álbum con animación slide ────────
                Item {
                    width:  parent.width
                    height: parent.width
                    clip: true

                    // Imagen saliente
                    Image {
                        id: artOut
                        width:  parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        opacity: 0
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artOut.width; height: artOut.height; radius: 10
                            }
                        }
                    }

                    // Imagen entrante
                    Image {
                        id: artIn
                        width:  parent.width
                        height: parent.height
                        source: root.artUrl
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        asynchronous: true

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artIn.width; height: artIn.height; radius: 10
                            }
                        }

                        onSourceChanged: {
                            // Guardar imagen anterior y animar
                            artOut.source  = artIn.source
                            artOut.x       = 0
                            artOut.opacity = 1

                            artIn.x = artIn.width
                            slideIn.restart()
                            slideOut.restart()
                        }

                        NumberAnimation on x {
                            id: slideIn
                            from: artIn.width; to: 0
                            duration: 360; easing.type: Easing.OutCubic
                        }
                    }

                    NumberAnimation {
                        id: slideOut
                        target: artOut; property: "x"
                        from: 0; to: -artOut.width
                        duration: 360; easing.type: Easing.OutCubic
                        onStopped: artOut.opacity = 0
                    }
                }

                // ── Título, álbum y artista ───────────────────
                Column {
                    width: parent.width
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.trackTitle || "Sin título"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        width: parent.width
                        text: root.trackAlbum
                        color: Qt.rgba(1,1,1,0.7)
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                    Text {
                        width: parent.width
                        text: root.trackArtist
                        color: Qt.rgba(1,1,1,0.55)
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }

                // ── Controles del popup ───────────────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18

                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 20
                        iconPath: root.iconsPath + "repeat-all.svg"
                        btnEnabled: root.player?.loopSupported ?? false
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconPath: root.iconsPath + "rewind.svg"
                        btnEnabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 48
                        iconPath: root.playing
                            ? root.iconsPath + "pause.svg"
                            : root.iconsPath + "play.svg"
                        btnEnabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconPath: root.iconsPath + "rewind.svg"
                        iconRotation: 180
                        btnEnabled: root.player?.canGoNext ?? false
                        onClicked: root.player?.next()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 20
                        iconPath: root.iconsPath + "shuffle-off.svg"
                        btnEnabled: root.player?.shuffleSupported ?? false
                    }
                }

                // ── Barra de progreso ─────────────────────────
                Column {
                    width: parent.width
                    spacing: 4
                    visible: root.player !== null

                    // Barra
                    Item {
                        id: progressArea
                        width: parent.width
                        height: 14
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            id: track
                            width: parent.width
                            height: 4
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(1,1,1,0.18)

                            Rectangle {
                                id: fill
                                // NO usar Behavior aquí — lo actualizamos manualmente
                                // para evitar conflicto entre binding y animación
                                width: track.width * root.progress
                                height: parent.height
                                radius: 2
                                color: "#ffffff"
                            }

                            // Handle
                            Rectangle {
                                width: 10; height: 10
                                radius: 5
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, fill.width - 5)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (!root.player?.canSeek) return
                                // Escribir en microsegundos
                                root.player.position = (mouse.x / width) * root.player.length
                            }
                        }
                    }

                    // Tiempos
                    Row {
                        width: parent.width

                        Text {
                            text: root.formatTime(root.positionSecs)
                            color: Qt.rgba(1,1,1,0.55)
                            font.pixelSize: 10
                        }

                        Item { width: parent.width - timeLeft.implicitWidth - timeRight.implicitWidth; height: 1
                            id: timeLeft
                        }

                        Text {
                            id: timeRight
                            text: root.formatTime(root.lengthSecs)
                            color: Qt.rgba(1,1,1,0.55)
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
