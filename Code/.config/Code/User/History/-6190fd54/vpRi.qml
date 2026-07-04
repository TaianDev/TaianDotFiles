import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root

    property int capsuleHeight: 28
    property int buttonSize:    20
    property string iconsPath: Qt.resolvedUrl("../assets/icons/")

    implicitHeight: capsuleHeight
    implicitWidth:  root.player !== null ? pillRow.implicitWidth + 24 : capsuleHeight
    visible:        true

    // ── Players ───────────────────────────────────────────────
    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length)
            activePlayerIndex = Math.max(0, playerList.length - 1)
    }

    readonly property var    player:      playerList.length > 0 ? playerList[activePlayerIndex] : null
    readonly property string trackTitle:  player?.trackTitle  ?? ""
    readonly property string trackArtist: player?.trackArtist ?? ""
    readonly property bool   playing:     player?.isPlaying   ?? false

    // ════════════════════════════════════════════════════════════
    // CACHÉ GLOBAL DE CARÁTULAS
    // Observa TODOS los players siempre, no solo el activo.
    // Clave: playerName (estable por sesión, no cambia con la pista)
    // Valor: última artUrl no vacía vista para ese player
    // ════════════════════════════════════════════════════════════
    property var artCache: ({})

    // Watchers dinámicos — uno por cada player en la lista
    Repeater {
        model: root.playerList

        Item {
            required property var modelData
            readonly property string pkey: modelData.playerName
                ?? modelData.identity ?? "unknown"

            // Observar artUrl de este player aunque no sea el activo
            readonly property string watchedArtUrl: modelData.trackArtUrl ?? ""

            onWatchedArtUrlChanged: {
                if (watchedArtUrl !== "") {
                    const updated = Object.assign({}, root.artCache)
                    updated[pkey] = watchedArtUrl
                    root.artCache = updated
                }
            }

            // Inicializar al aparecer
            Component.onCompleted: {
                if (watchedArtUrl !== "") {
                    const updated = Object.assign({}, root.artCache)
                    updated[pkey] = watchedArtUrl
                    root.artCache = updated
                }
            }
        }
    }

    // Clave del player activo
    readonly property string activePkey: player?.playerName
        ?? player?.identity ?? "unknown"

    // Carátula estable del player activo — desde el caché global
    readonly property string stableArtUrl: artCache[activePkey] ?? ""

    property bool popupOpen: false

    // Ruta al disco por defecto
    property string defaultArtPath: Qt.resolvedUrl("../assets/music-disc.jpg")

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

    // ── Cápsula ───────────────────────────────────────────────
    Rectangle {
        id: capsule
        anchors.fill: parent
        radius: capsuleHeight / 2
        color:  Qt.rgba(1, 1, 1, 0.08)
        border.width: 0.5
        border.color: Qt.rgba(1, 1, 1, 0.12)
        clip: true

        Item {
            anchors.fill: parent
            visible: root.stableArtUrl !== ""

            Image {
                id: artBg
                anchors.centerIn: parent
                source: root.stableArtUrl
                width: parent.width + 20; height: parent.height + 20
                fillMode: Image.PreserveAspectCrop
                cache: true; asynchronous: true
                sourceSize.width: 120; sourceSize.height: 120
            }
            FastBlur { anchors.fill: artBg; source: artBg; radius: 40 }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.58) }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 20; height: 20; radius: 10
                color: "transparent"
                visible: true
                clip: true
                Image {
                    anchors.fill: parent
                    source: root.stableArtUrl !== ""
                        ? root.stableArtUrl
                        : root.defaultArtPath
                    fillMode: Image.PreserveAspectCrop
                    cache: true; asynchronous: true
                    opacity: root.player !== null ? 1.0 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle { width: 20; height: 20; radius: 10 }
                }
            }

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
                    iconRot: 180
                    btnEnabled: root.player?.canGoNext ?? false
                    onClicked: root.player?.next()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.player !== null) root.popupOpen = !root.popupOpen
        }
    }

    WheelHandler {
        onWheel: event => {
            if (!root.player) return
            const d = event.angleDelta.y / 120 * 0.05
            root.player.volume = Math.max(0, Math.min(1, (root.player.volume ?? 0) + d))
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
