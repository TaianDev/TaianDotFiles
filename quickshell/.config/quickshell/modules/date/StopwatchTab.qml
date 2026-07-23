import QtQuick
import QtQuick.Layouts
import "../../core"
import "../../components"

Item {
    id: root
    
    property color textMain: "#ffffff"
    property color bgLighter: "#2d2d2d"
    property string iconsPath: widgetRef ? widgetRef.iconsPath : Qt.resolvedUrl("../../assets/icons/")
    
    // 🌟 Recibe la referencia centralizada
    property var widgetRef: null

    // Lee los valores reales desde la barra
    property int elapsedMs: widgetRef ? widgetRef.swElapsedMs : 0
    property bool running: widgetRef ? widgetRef.swRunning : false

    function formatSW(ms) {
        let h = Math.floor(ms / 3600000).toString().padStart(2, '0')
        let m = Math.floor((ms % 3600000) / 60000).toString().padStart(2, '0')
        let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
        let d = Math.floor((ms % 1000) / 100)
        return h + ":" + m + ":" + s + "." + d
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.formatSW(root.elapsedMs)
            color: root.textMain
            font.pixelSize: 48
            font.weight: Font.Thin
            style: Text.Outline
            styleColor: Qt.rgba(1, 1, 1, 0.2)
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // 🌟 Botón de Pausa / Play con Hover
            Rectangle {
                width: 48; height: 48; radius: 24
                
                // Efecto hover: Se aclara el gris de fondo
                color: playMa.containsMouse ? Qt.lighter(root.bgLighter, 1.4) : root.bgLighter
                Behavior on color { ColorAnimation { duration: 150 } }
                
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + (root.running ? "pause.svg" : "play.svg")
                    size: 20
                    tint: root.textMain
                }
                
                MouseArea {
                    id: playMa
                    anchors.fill: parent
                    hoverEnabled: true // Necesario para detectar cuando el ratón pasa por encima
                    cursorShape: Qt.PointingHandCursor
                    // Envía la orden al padre
                    onClicked: { if (root.widgetRef) root.widgetRef.swRunning = !root.widgetRef.swRunning } 
                }
            }

            // 🌟 Botón de Detener con Hover Rojo
            Rectangle {
                width: 48; height: 48; radius: 24
                
                // Efecto hover: Pasa del gris al rojo destructivo para indicar "Detener/Borrar"
                color: stopMa.containsMouse ? Theme.err : root.bgLighter
                Behavior on color { ColorAnimation { duration: 150 } }
                
                SvgIcon {
                    anchors.centerIn: parent
                    source: root.iconsPath + "stop.svg"
                    size: 20
                    tint: root.textMain
                }
                
                MouseArea {
                    id: stopMa
                    anchors.fill: parent
                    hoverEnabled: true // Necesario para detectar cuando el ratón pasa por encima
                    cursorShape: Qt.PointingHandCursor
                    // Resetea el estado en el padre
                    onClicked: { 
                        if (root.widgetRef) {
                            root.widgetRef.swRunning = false; 
                            root.widgetRef.swElapsedMs = 0 
                        }
                    }
                }
            }
        }
    }
}