import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Services.Mpris

// Uso en Bar.qml (dentro de mainBody):
//
//   MusicWidget {
//       id: music
//       parentWindow: flareBar          // <-- pasar el PanelWindow
//       anchors.right: parent.right
//       anchors.verticalCenter: parent.verticalCenter
//       anchors.rightMargin: 20
//   }
//
// Y en Bar.qml al mismo nivel que mainBody (hijo de PanelWindow):
//   MusicPopup { widgetRef: music; parentWindow: flareBar }

Item {
    id: root

    property int capsuleHeight: 28
    property int buttonSize:    20

    // Ruta a tus SVGs — ajusta si es diferente
    property string iconsPath: Qt.resolvedUrl("../assets/icons/")

    implicitHeight: capsuleHeight
    implicitWidth:  root.player !== null ? pillRow.implicitWidth + 24 : 0
    visible:        root.player !== null

    // ── Estado ────────────────────────────────────────────────
    property int activePlayerIndex: 0
    property var playerList: Mpris.players.values

    onPlayerListChanged: {
        if (activePlayerIndex >= playerList.length)
            activePlayerIndex = Math.max(0, playerList.length - 1)
    }

    readonly property var    player:      playerList.length > 0 ? playerList[activePlayerIndex] : null
    readonly property string trackTitle:  player?.trackTitle  ?? ""
    readonly property string trackArtist: player?.trackArtist ?? ""
    readonly property string artUrl:      player?.trackArtUrl ?? ""
    readonly property bool   playing:     player?.isPlaying   ?? false

    property bool popupOpen: false

    // ── Componente botón SVG ──────────────────────────────────
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
            id: ico
            anchors.centerIn: parent
            width:  btn.size * 0.78
            height: btn.size * 0.78
            source: btn.iconPath
            sourceSize.width:  width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            rotation: btn.iconRot
            cache: false
            layer.enabled: true
            layer.effect: ColorOverlay { color: "#ffffff" }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
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
            FastBlur { anchors.fill: artBg; source: artBg; radius: 40 }
            Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.58) }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            // Miniatura circular
            Rectangle {
                width: 20; height: 20; radius: 10
                color: "transparent"
                visible: root.artUrl !== ""
                clip: true
                Image {
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    cache: false; asynchronous: true
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
            onClicked: root.popupOpen = !root.popupOpen
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
