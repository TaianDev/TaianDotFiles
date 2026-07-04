import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: root
    height: 32
    Layout.fillWidth: true

    property string iconSource: ""
    property color  activeColor: "#ffffff"
    property real   value: 0
    property real   to: 100
    property bool   isDragging: slider.pressed

    signal moved(real val)

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // Ícono del Slider
        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Image {
                id: icn; anchors.fill: parent
                source: root.iconSource; visible: false
            }
            ColorOverlay {
                anchors.fill: icn; source: icn; color: root.activeColor
            }
        }

        // Barra Estilo iOS
        Slider {
            id: slider
            Layout.fillWidth: true
            from: 0; to: root.to
            value: root.value
            
            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 24
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.1)
                
                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: root.activeColor
                    radius: 12
                }
            }
            handle: Item {} // Oculta la bolita nativa, dejando solo la barra gruesa
            
            onMoved: root.moved(value)
        }
    }
}