import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris

// Declarar al mismo nivel que mainBody, hijo directo del PanelWindow:
//
//   MusicPopup {
//       id: musicPopup
//       widgetRef: music          // el MusicWidget
//       parentWindow: flareBar    // el PanelWindow
//   }

PopupWindow {
    id: popup

    required property var  widgetRef
    required property var  parentWindow

    visible: widgetRef?.popupOpen ?? false
    color:   "transparent"
    width:   320
    height:  contentCol.implicitHeight + 40

    // Anclar bajo el widget, alineado a la derecha
    anchor.window: parentWindow
    anchor.rect: Qt.rect(
        widgetRef.mapToItem(null, 0, 0).x + widgetRef.width - popup.width,
        parentWindow.height + 4,
        popup.width,
        popup.height
    )

    onVisibleChanged: if (!visible && widgetRef) widgetRef.popupOpen = false

    // ── Shortcuts internos al widget ──────────────────────────
    readonly property var    player:      widgetRef?.player      ?? null
    readonly property string artUrl:      widgetRef?.artUrl      ?? ""
    readonly property bool   playing:     widgetRef?.playing     ?? false
    readonly property string trackTitle:  widgetRef?.trackTitle  ?? ""
    readonly property string trackArtist: widgetRef?.trackArtist ?? ""
    readonly property string trackAlbum:  widgetRef?.player?.trackAlbum ?? ""
    readonly property string iconsPath:   widgetRef?.iconsPath   ?? ""
    readonly property var    playerList:  widgetRef?.playerList  ?? []

    // Posición en segundos (Mpris usa microsegundos)
    readonly property real positionSecs: (player?.position ?? 0) / 1_000_000
    readonly property real lengthSecs:   (player?.length   ?? 0) / 1_000_000
    readonly property real progress:     lengthSecs > 0
        ? Math.min(1, positionSecs / lengthSecs) : 0

    function formatTime(secs) {
        if (!secs || secs <= 0) return "0:00"
        const s = Math.floor(secs) % 60
        const m = Math.floor(secs / 60)
        return `${m}:${s.toString().padStart(2, "0")}`
    }

    // ── Botón SVG interno ─────────────────────────────────────
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
    // CONTENIDO DEL POPUP
    // ══════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        radius: 16
        color:  Qt.rgba(0.08, 0.08, 0.08, 0.92)
        border.width: 0.5
        border.color: Qt.rgba(1, 1, 1, 0.12)
        clip: true

        // Fondo con arte blureado
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
                cache: false; asynchronous: true

                Behavior on source {
                    SequentialAnimation {
                        NumberAnimation { target: popupBg; property: "opacity"; to: 0; duration: 180 }
                        PropertyAction  {}
                        NumberAnimation { target: popupBg; property: "opacity"; to: 1; duration: 300 }
                    }
                }
            }
            FastBlur { anchors.fill: popupBg; source: popupBg; radius: 90 }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.68) }
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle { width: popup.width; height: popup.height; radius: 16 }
        }

        Column {
            id: contentCol
            anchors {
                top: parent.top; left: parent.left; right: parent.right
                margins: 20
            }
            spacing: 16

            // ── Selector de players ───────────────────────────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                visible: popup.playerList.length > 1

                Repeater {
                    model: popup.playerList

                    Rectangle {
                        width: 34; height: 34; radius: 8
                        color: index === (popup.widgetRef?.activePlayerIndex ?? 0)
                            ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.06)
                        border.width: index === (popup.widgetRef?.activePlayerIndex ?? 0) ? 1 : 0
                        border.color: Qt.rgba(1,1,1,0.35)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Image {
                            anchors { fill: parent; margins: 7 }
                            source: {
                                const entry = DesktopEntries.byId(modelData.desktopEntry ?? "")
                                if (!entry) return ""
                                // iconPath con segundo arg "" evita el cuadrado morado
                                return Quickshell.iconPath(entry.icon, "")
                            }
                            fillMode: Image.PreserveAspectFit
                            cache: false; asynchronous: true
                            // Fallback: mostrar inicial si no hay icono
                            visible: status === Image.Ready
                        }

                        // Texto fallback si no hay icono
                        Text {
                            anchors.centerIn: parent
                            text: (modelData.identity ?? "?")[0].toUpperCase()
                            color: "#ffffff"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            visible: {
                                const entry = DesktopEntries.byId(modelData.desktopEntry ?? "")
                                return !entry
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (popup.widgetRef) popup.widgetRef.activePlayerIndex = index
                        }
                    }
                }
            }

            // ── Arte del álbum con animación slide ────────────
            Item {
                width: parent.width
                height: parent.width
                clip: true

                Image {
                    id: artOut
                    width: parent.width; height: parent.height
                    fillMode: Image.PreserveAspectFit
                    cache: false; opacity: 0
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
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle { width: artIn.width; height: artIn.height; radius: 10 }
                    }

                    onSourceChanged: {
                        artOut.source  = artIn.source
                        artOut.x       = 0
                        artOut.opacity = 1
                        artIn.x        = artIn.width
                        slideIn.restart()
                        slideOut.restart()
                    }

                    NumberAnimation on x {
                        id: slideIn
                        from: artIn.width; to: 0
                        duration: 350; easing.type: Easing.OutCubic
                    }
                }

                NumberAnimation {
                    id: slideOut
                    target: artOut; property: "x"
                    from: 0; to: -artOut.width
                    duration: 350; easing.type: Easing.OutCubic
                    onStopped: artOut.opacity = 0
                }
            }

            // ── Título, álbum, artista ────────────────────────
            Column {
                width: parent.width
                spacing: 3

                Text {
                    width: parent.width
                    text: popup.trackTitle || "Sin título"
                    color: "#ffffff"
                    font.pixelSize: 15; font.weight: Font.Medium
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    width: parent.width
                    text: popup.trackAlbum
                    color: Qt.rgba(1,1,1,0.65)
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    visible: text !== ""
                }
                Text {
                    width: parent.width
                    text: popup.trackArtist
                    color: Qt.rgba(1,1,1,0.5)
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    visible: text !== ""
                }
            }

            // ── Controles play/pause/anterior/siguiente ───────
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                SvgBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    iconPath: popup.iconsPath + "rewind.svg"
                    btnEnabled: popup.player?.canGoPrevious ?? false
                    onClicked: popup.player?.previous()
                }
                SvgBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 50
                    iconPath: popup.playing
                        ? popup.iconsPath + "pause.svg"
                        : popup.iconsPath + "play.svg"
                    btnEnabled: popup.player?.canTogglePlaying ?? false
                    onClicked: popup.player?.togglePlaying()
                }
                SvgBtn {
                    anchors.verticalCenter: parent.verticalCenter
                    size: 30
                    iconPath: popup.iconsPath + "rewind.svg"
                    iconRot: 180
                    btnEnabled: popup.player?.canGoNext ?? false
                    onClicked: popup.player?.next()
                }
            }

            // ── Barra de progreso ─────────────────────────────
            Column {
                width: parent.width
                spacing: 4
                visible: popup.player !== null

                Item {
                    width: parent.width
                    height: 14

                    Rectangle {
                        id: track
                        width: parent.width; height: 4; radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(1,1,1,0.18)

                        // fill reactivo directo — sin Behavior para evitar conflicto
                        Rectangle {
                            id: fill
                            width: track.width * popup.progress
                            height: parent.height; radius: 2
                            color: "#ffffff"
                        }

                        // Handle
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
                            // position se escribe en microsegundos
                            popup.player.position = (mouse.x / width) * popup.player.length
                        }
                    }
                }

                // Tiempos
                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: popup.formatTime(popup.positionSecs)
                        color: Qt.rgba(1,1,1,0.5)
                        font.pixelSize: 10
                    }
                    Text {
                        anchors.right: parent.right
                        text: popup.formatTime(popup.lengthSecs)
                        color: Qt.rgba(1,1,1,0.5)
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
