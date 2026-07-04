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
    property int popupWidth:    340
    property int popupHeight:   480 // Ampliado para encajar todo el contenido

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
    property string trackAlbum:  player?.trackAlbum  ?? ""
    property string trackArtist: player?.trackArtist ?? ""
    property string artUrl:      player?.trackArtUrl ?? ""
    property bool   playing:     player?.playbackState === MprisPlaybackState.Playing

    // ── Popup visible ─────────────────────────────────────────
    property bool popupOpen: false

    // ══════════════════════════════════════════════════════════
    // 1. CÁPSULA PRINCIPAL (Módulo en Barra)
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
            anchors.centerIn: parent
            spacing: 8

            // Miniatura circular
            Rectangle {
                width: 20; height: 20
                radius: 10
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

            // Controles horizontales SVG
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
                    iconRotation: 180
                    enabled: root.player?.canGoNext ?? false
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

    // ══════════════════════════════════════════════════════════
    // 2. POPUP EMERGENTE (Diseño Fiel a la Imagen)
    // ══════════════════════════════════════════════════════════
    PopupWindow {
        id: popup
        visible: root.popupOpen
        color: "transparent"

        implicitWidth:  root.popupWidth
        implicitHeight: root.popupHeight

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
            radius: 16
            color: Qt.rgba(0.1, 0.1, 0.1, 0.85) // Ligeramente más transparente
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)
            clip: true

            // Arte de fondo difuminado
            Item {
                anchors.fill: parent
                visible: root.artUrl !== ""

                Image {
                    id: popupArtBg
                    anchors.centerIn: parent
                    source: root.artUrl
                    width: parent.width + 60
                    height: parent.height + 60
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                }
                FastBlur {
                    anchors.fill: popupArtBg
                    source: popupArtBg
                    radius: 64 // Difuminado intenso como en la imagen
                }
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.4) // Oscurecido suave
                }
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: root.popupWidth; height: root.popupHeight; radius: 16 }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20

                // ── 1. Selector de Reproductores (Top) ──
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6
                    
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12
                        visible: root.playerList.length > 0

                        Repeater {
                            model: root.playerList
                            Rectangle {
                                width: 36; height: 36
                                radius: 8
                                // Resaltar el seleccionado
                                color: index === root.activePlayerIndex ? Qt.rgba(1,1,1,0.2) : "transparent"
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
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activePlayerIndex = index
                                }
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.player ? root.player.identity : "Sin Reproductor"
                        color: "#ffffff"
                        font.pixelSize: 13
                    }
                }

                // ── 2. Arte del Álbum Grande ──
                Rectangle {
                    width: 220; height: 220
                    anchors.horizontalCenter: parent.horizontalCenter
                    radius: 8
                    color: Qt.rgba(1,1,1,0.05)

                    Image {
                        anchors.fill: parent
                        source: root.artUrl
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 220; height: 220; radius: 8 }
                        }
                    }
                }

                // ── 3. Info de la Pista (3 líneas) ──
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
                        text: root.trackAlbum
                        color: "#eeeeee"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                    Text {
                        width: parent.width
                        text: root.trackArtist
                        color: "#cccccc"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                    }
                }

                // ── 4. Controles SVG (Jerarquía de tamaños) ──
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20
                    anchors.verticalCenterOffset: 10

                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 20
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/repeat-all.svg"
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 46 // Play/Pause mucho más grande
                        iconPath: root.playing ? "file:///home/taianlux/.config/quickshell/assets/icons/pause.svg" : "file:///home/taianlux/.config/quickshell/assets/icons/play.svg"
                        enabled: root.player?.canTogglePlaying ?? false
                        onClicked: root.player?.togglePlaying()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 28
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                        iconRotation: 180
                        enabled: root.player?.canGoNext ?? false
                        onClicked: root.player?.next()
                    }
                    SvgBtn {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 20
                        iconPath: "file:///home/taianlux/.config/quickshell/assets/icons/shuffle-off.svg"
                    }
                }

                // ── 5. Barra de progreso con indicador de tiempo ──
                Row {
                    width: parent.width
                    spacing: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.player !== null

                    Timer {
                        running: root.playing && popup.visible
                        interval: 1000
                        repeat: true
                        onTriggered: progressBarItem.updateProgress()
                    }

                    Text {
                        text: formatTime(root.player?.position)
                        color: Qt.rgba(1,1,1,0.8)
                        font.pixelSize: 11
                        width: 32
                    }

                    // Contenedor de la barra y el punto
                    Item {
                        id: progressBarItem
                        width: parent.width - 88
                        height: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.rgba(1,1,1,0.2)

                            // Barra de llenado
                            Rectangle {
                                id: fillRect
                                width: root.player && root.player.length > 0 ? parent.width * (root.player.position / root.player.length) : 0
                                height: parent.height
                                radius: 2
                                color: "#ffffff"
                                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                            }

                            // El "Puntito" (Handle)
                            Rectangle {
                                width: 10; height: 10
                                radius: 5
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, fillRect.width - 5) // Se mueve junto con la barra
                                Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (!root.player?.canSeek) return
                                root.player.position = (mouse.x / width) * root.player.length
                                progressBarItem.updateProgress()
                            }
                        }

                        function updateProgress() {
                            if (!root.player || root.player.length <= 0) return
                            fillRect.width = parent.width * (root.player.position / root.player.length)
                        }
                    }

                    Text {
                        text: formatTime(root.player?.length)
                        color: Qt.rgba(1,1,1,0.8)
                        font.pixelSize: 11
                        width: 32
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    // ══════════════════════════════════════════════════════════
    // FUNCIONES HELPERS & COMPONENTES INTERNOS
    // ══════════════════════════════════════════════════════════
    function formatTime(seconds) {
        if (!seconds || seconds < 0) return "0:00"
        const s = Math.floor(seconds) % 60
        const m = Math.floor(seconds / 60)
        return `${m}:${s.toString().padStart(2, "0")}`
    }

    component SvgBtn: Item {
        id: btn
        property int size: 24
        property string iconPath: ""
        property int iconRotation: 0
        property bool enabled: true
        signal clicked()

        width: size
        height: size
        opacity: enabled ? (ma.containsMouse ? 0.7 : 1.0) : 0.4

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Image {
            id: iconImg
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.height * 0.8
            source: btn.iconPath
            sourceSize.width: width
            sourceSize.height: height
            rotation: btn.iconRotation
            fillMode: Image.PreserveAspectFit
            visible: false 
        }

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