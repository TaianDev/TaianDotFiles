import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland // 🌟 CRUCIAL: Necesario para usar AnchorEdge
import Quickshell.Services.Mpris

Item {
    id: root
    width: mprisCapsule.width
    height: 28

    // Recibe la ventana base desde Bar.qml
    property var hostWindow 

    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: activePlayer !== null

    Rectangle {
        id: mprisCapsule
        height: root.height
        // Si hay música, usa el ancho del contenido + márgenes. Si no, se oculta (0).
        width: hasPlayer ? contentRow.implicitWidth + 24 : 0
        radius: height / 2
        color: "#1a1a1a"
        clip: true
        visible: width > 0

        // Animación suave al abrir/cerrar el reproductor
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuart } }

        // 1. FONDO DIFUMINADO
        Image {
            id: capsuleBg
            anchors.fill: parent
            source: hasPlayer ? activePlayer.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            source: capsuleBg
            anchors.fill: parent
            blurEnabled: true
            blurMax: 32
            blur: 1.0
            colorization: 0.8
            colorizationColor: "#000000"
        }

        // 🌟 CORRECCIÓN 1: MouseArea detrás de los controles
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mprisPopup.visible = !mprisPopup.visible
        }

        // 2. CONTENIDO (Portada y Controles)
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 12

            // Miniatura circular de la canción
            Rectangle {
                width: 20
                height: 20
                radius: 10
                anchors.verticalCenter: parent.verticalCenter
                color: "#333333"

                Image {
                    anchors.fill: parent
                    source: hasPlayer ? activePlayer.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: Rectangle { width: 20; height: 20; radius: 10 }
                    }
                }
            }

            // Los 3 controles horizontales
            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                MprisButton {
                    iconSource: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                    onClicked: if(activePlayer) activePlayer.previous()
                }
                MprisButton {
                    iconSource: activePlayer && activePlayer.playbackStatus === Mpris.PlaybackStatus.Playing 
                                ? "file:///home/taianlux/.config/quickshell/assets/icons/pause.svg" 
                                : "file:///home/taianlux/.config/quickshell/assets/icons/play.svg"
                    onClicked: if(activePlayer) activePlayer.playPause()
                }
                MprisButton {
                    iconSource: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                    iconRotation: 180 // Rotamos para reciclar el SVG
                    onClicked: if(activePlayer) activePlayer.next()
                }
            }
        }
    }

    // 🌟 CORRECCIÓN 2: Menú Flotante con mapeo de coordenadas riguroso
    MprisMenu {
        id: mprisPopup
        player: root.activePlayer
        visible: false 

        anchor {
            window: root.hostWindow
            
            // Convertimos las coordenadas relativas en un objeto 'rect' nativo
            rect: {
                var mapped = root.mapToItem(null, 0, 0, root.width, root.height)
                return Qt.rect(mapped.x, mapped.y, mapped.width, mapped.height)
            }
            
            edges: AnchorEdge.Bottom
        }
    }
}