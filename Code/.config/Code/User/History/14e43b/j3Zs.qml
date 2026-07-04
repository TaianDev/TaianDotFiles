import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

PopupWindow {
    id: popup
    width: 340
    height: 420
    color: "transparent"

    // Recibimos el reproductor activo desde el widget de la barra
    property var player: null

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#1e1e2e" // Color base oscuro
        clip: true

        // 1. FONDO DIFUMINADO (Cover Art)
        Image {
            id: bgImage
            anchors.fill: parent
            source: player && player.artUrl ? player.artUrl : ""
            fillMode: Image.PreserveAspectCrop
            visible: false 
        }

        MultiEffect {
            source: bgImage
            anchors.fill: parent
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            colorization: 0.7
            colorizationColor: "#111111" // Oscurecemos la imagen para que el texto resalte
        }

        // 2. CONTENIDO PRINCIPAL
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Nombre del reproductor (Top)
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: player ? player.identity : "Sin Reproductor"
                color: "#ffffff"
                font.bold: true
                font.pixelSize: 14
            }

            // Portada Central Grande
            Rectangle {
                width: 200
                height: 200
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 12
                color: "#333333"

                Image {
                    anchors.fill: parent
                    source: player && player.artUrl ? player.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: Rectangle { width: 200; height: 200; radius: 12 }
                    }
                }
            }

            // Información de la Pista (Title & Artist)
            Column {
                width: parent.width
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: player ? player.trackTitle : "Sin Título"
                    color: "#ffffff"
                    font.bold: true
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: player && player.trackArtists.length > 0 ? player.trackArtists.join(", ") : "Artista Desconocido"
                    color: "#aaaaaa"
                    font.pixelSize: 13
                }
            }

            // Controles de Reproducción
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 16

                MprisButton {
                    iconSource: "file:///home/taianlux/.config/quickshell/assets/icons/shuffle-off.svg"
                    onClicked: if(player) player.shuffle = !player.shuffle
                }
                MprisButton {
                    iconSource: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                    onClicked: if(player) player.previous()
                }
                MprisButton {
                    width: 32; height: 32
                    iconSource: player && player.playbackStatus === Mpris.PlaybackStatus.Playing 
                                ? "file:///home/taianlux/.config/quickshell/assets/icons/pause.svg" 
                                : "file:///home/taianlux/.config/quickshell/assets/icons/play.svg"
                    onClicked: if(player) player.playPause()
                }
                MprisButton {
                    // Usamos rewind y lo rotamos 180° para que sirva de 'Next'
                    iconSource: "file:///home/taianlux/.config/quickshell/assets/icons/rewind.svg"
                    iconRotation: 180 
                    onClicked: if(player) player.next()
                }
                MprisButton {
                    iconSource: "file:///home/taianlux/.config/quickshell/assets/icons/repeat-all.svg"
                }
            }
        }
    }
}