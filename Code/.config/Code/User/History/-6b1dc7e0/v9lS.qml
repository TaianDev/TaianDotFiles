import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

Item {
    id: root

    // ── Tamaños ──────────────────────────────────────────────
    property int capsuleHeight: 28
    property int buttonSize:    20
    property int popupWidth:    320
    property int popupHeight:   420

    implicitHeight: capsuleHeight
    implicitWidth:  player ? pillRow.implicitWidth + 24 : 0
    visible: player !== null

    // ── Player activo y Propiedades ───────────────────────────
    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length) activePlayerIndex = 0
    }

    property var player:  playerList.length > 0 ? playerList[activePlayerIndex] : null
    property string trackTitle:  player?.trackTitle  ?? "Sin título"
    property string trackArtist: player?.trackArtist ?? ""
    property string artUrl:      player?.trackArtUrl ?? ""
    property bool   playing:     player?.playbackState === MprisPlaybackState.Playing

    // ── Popup visible ─────────────────────────────────────────
    property bool popupOpen: false

    // ══════════════════════════════════════════════════════════
    // 1. CÁPSULA PRINCIPAL (Barra)
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
                color: Qt.rgba(0, 0, 0, 0.6) // Oscurecer para que resalten los iconos
            }
        }

        // Contenido de la cápsula (Miniatura + 3 Botones)
        RowLayout {
            id: pillRow
            anchors {
                centerIn: parent
            }
            spacing: 8

            // Miniatura del álbum circular
            Rectangle {
                width: 20; height: 20
                radius: 10 // Mitad para que sea círculo
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
                    maskSource: Rectangle { width: 20; height: 20; radius: 10 }
                }
            }

            // Los 3 botones horizontales (SVG)
            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                SvgBtn {
                    size: root.buttonSize
                    iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player?.previous()
                }

                SvgBtn {
                    size: root.buttonSize + 2
                    iconPath: root.playing ? "file:///home/taianlux/.config/quickshell/assets/icons/pause.svg" : "file:///home/taianlux/.config/quickshell/assets/icons/play.svg"
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player?.togglePlaying()
                }

                SvgBtn {
                    size: root.buttonSize
                    iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                    iconRotation: 180 // Rotamos el rewind para que sea Next
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }
            }
        }

        // Clic Derecho para abrir el popup
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.popupOpen = !root.popupOpen
        }
    }

    // ══════════════════════════════════════════════════════════
    // 2. POPUP EMERGENTE
    // ══════════════════════════════════════════════════════════
    PopupWindow {
        id: popup
        visible: root.popupOpen
        color: "transparent"

        implicitWidth:  root.popupWidth
        implicitHeight: root.popupHeight

        // Anclar usando la lógica robusta de la base
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

            // Arte de fondo difuminado
            Item {
                anchors.fill: parent
                visible: root.artUrl !== ""

                Image {
                    id: popupArtBg
                    anchors.centerIn: parent
                    source: root.artUrl
                    width: parent.width + 40
                    height: parent.height + 40
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
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

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: root.popupWidth; height: root.popupHeight; radius: 14 }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // ── Cabecera: Icono y Nombre del Reproductor ──
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    
                    Image {
                        width: 18; height: 18
                        source: {
                            if (!root.player) return ""
                            const entry = DesktopEntries.byId(root.player.desktopEntry ?? "")
                            return entry ? Quickshell.iconPath(entry.icon, "") : ""
                        }
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    Text {
                        text: root.player ? root.player.identity : "Sin Reproductor"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }

                // ── Arte del Álbum Grande ──
                Rectangle {
                    width: 220; height: 220
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 12
                    color: Qt.rgba(1,1,1,0.1)

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 220; height: 220; radius: 12 }
                        }
                    }
                }

                // ── Título y artista ──
                Column {
                    width: parent.width
                    spacing: 4

                    Text {
                        width: parent.width
                        text: root.trackTitle
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.bold: true
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        width: parent.width
                        text: root.trackArtist
                        color: Qt.rgba(1,1,1,0.6)
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }

                // ── Barra de progreso ──
                Item {
                    width: parent.width
                    height: 4
                    visible: root.player !== null

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
                            color: "#ffffff"
                            width: 0

                            function updateProgress() {
                                if (!root.player || root.player.length <= 0) return
                                width = parent.width * (root.player.position / root.player.length)
                            }
                            Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            if (!root.player?.canSeek) return
                            root.player.position = (mouse.x / width) * root.player.length
                            progressBar.updateProgress()
                        }
                    }
                }

                // ── Controles (5 Botones SVG) ──
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16

                    SvgBtn {
                        size: 24
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/shuffle-off.svg"
                        onClicked: root.player?.toggleShuffle()
                    }
                    SvgBtn {
                        size: 32
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }
                    SvgBtn {
                        size: 42
                        iconPath: root.playing ? "file:///home/taianlux/.config/quickshell/assets/icons/pause.svg" : "file:///home/taianlux/.config/quickshell/assets/icons/play.svg"
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }
                    SvgBtn {
                        size: 32
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                        iconRotation: 180
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player?.next()
                    }
                    SvgBtn {
                        size: 24
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/repeat-all.svg"
                        // La lógica de repetición en MPRIS varía por reproductor, aquí dejamos la base visual
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════
    // 3. COMPONENTE REUTILIZABLE: Botón SVG
    // ══════════════════════════════════════════════════════════
    component SvgBtn: Item {
        id: btn
        property int size: 24
        property string iconPath: ""
        property int iconRotation: 0
        property bool enabled: true
        signal clicked()

        width: size
        height: size
        opacity: enabled ? (ma.containsMouse ? 0.7 : 1.0) : 0.3

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Image {
            id: iconImg
            anchors.centerIn: parent
            width: parent.width * 0.7
            height: parent.height * 0.7
            source: btn.iconPath
            sourceSize.width: width
            sourceSize.height: height
            rotation: btn.iconRotation
            fillMode: Image.PreserveAspectFit
            visible: false // Se oculta porque ColorOverlay se encarga de pintarlo
        }

        // Pintamos el SVG de blanco garantizado
        ColorOverlay {
            anchors.fill: iconImg
            source: iconImg
            color: "#ffffff"
            rotation: btn.iconRotation
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (btn.enabled) btn.clicked()
        }
    }
}