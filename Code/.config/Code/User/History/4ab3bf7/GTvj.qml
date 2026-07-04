import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    height: 32
    Layout.fillWidth: true

    property string iconSource: ""
    property string mutedIconSource: ""
    property color  activeColor: "#ffffff"
    property real   value: 0
    property real   to: 100
    property bool   isDragging: slider.pressed
    
    // Propiedades de Muteo
    property bool   canMute: false
    property bool   isMuted: false

    signal moved(real val)
    signal toggleMuteClicked()

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // ── Ícono Interactivo ──
        Item {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            
            Image {
                id: icn
                anchors.fill: parent
                // Alterna entre el ícono normal y el muteado
                source: (root.isMuted && root.mutedIconSource !== "") ? root.mutedIconSource : root.iconSource
                visible: false
            }
            
            ColorOverlay {
                anchors.fill: icn
                source: icn
                // Si está muteado se pone gris semitransparente
                color: root.isMuted ? Qt.rgba(1, 1, 1, 0.4) : root.activeColor
            }
            
            MouseArea {
                anchors.fill: parent
                enabled: root.canMute
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.toggleMuteClicked()
            }
        }

        // ── Slider Delgado (macOS Style) ──
        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0; to: root.to
            value: root.value
            
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 6 // 🌟 Perfil ultra delgado
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.15)
                
                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: root.isMuted ? Qt.rgba(1, 1, 1, 0.4) : root.activeColor
                    radius: 3
                }
            }
            
            // 🌟 Tirador Circular con Sombra
            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 16
                height: 16
                radius: 8
                color: "#ffffff"
                border.color: Qt.rgba(0, 0, 0, 0.1)
                border.width: 1
                
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: 4
                    samples: 8
                    verticalOffset: 2
                }
            }
            
            // 🌟 Acelerador para que el mouse no se trabe al arrastrar
            Timer {
                id: throttle
                interval: 30
                property real pendingVal: -1
                onTriggered: {
                    if (pendingVal >= 0) {
                        root.moved(pendingVal)
                        pendingVal = -1
                    }
                }
            }
            
            onValueChanged: {
                if (pressed) {
                    throttle.pendingVal = value
                    throttle.restart()
                }
            }
        }
    }
}