import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

Item {
    id: root
    width: mprisCapsule.width
    height: 28

    // 🌟 NUEVO: Variable para recibir la ventana base desde Bar.qml
    property var hostWindow 

    property var activePlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: activePlayer !== null
    // 🌟 LA CÁPSULA
    Rectangle {
        id: mprisCapsule
        height: root.height
        width: hasPlayer ? contentRow.implicitWidth + 24 : 0
        radius: height / 2
        color: "#1a1a1a"
        clip: true
        visible: hasPlayer

        // Fondo difuminado basado en el Cover Art
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
            blurMax: 20
            blur: 1.0
            colorization: 0.6
            colorizationColor: "#000000"
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 12

            // Miniatura circular
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
                    iconRotation: 180
                    onClicked: if(activePlayer) activePlayer.next()
                }
            }
        }

        // Clic Derecho para abrir el menú
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                mprisPopup.visible = !mprisPopup.visible
            }
        }
    }

    // Instancia de la ventana flotante anclada a este widget
    MprisMenu {
        id: mprisPopup
        player: root.activePlayer
        visible: false // Oculto por defecto hasta hacer clic derecho

        anchor {
            // Se ancla a la ventana que le pasaremos desde la barra
            window: root.hostWindow
            
            // Mapea las coordenadas (x, y, ancho, alto) de este widget hacia la ventana principal
            rect: root.mapToItem(null, 0, 0, root.width, root.height)
            
            // Despliega el menú hacia abajo
            edges: AnchorEdge.Bottom
        }
    }
}