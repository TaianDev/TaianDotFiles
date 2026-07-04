import QtQuick
import QtQuick.Effects

Item {
    id: root
    width: 24
    height: 24

    property string iconSource
    property int iconRotation: 0
    signal clicked()

    Image {
        id: iconImg
        anchors.centerIn: parent
        width: 16
        height: 16
        source: root.iconSource
        rotation: root.iconRotation
        sourceSize.width: 16
        sourceSize.height: 16
        // Pintamos el SVG de blanco
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: "#ffffff"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
        
        // Efecto visual al pasar el ratón
        onEntered: iconImg.opacity = 0.7
        onExited: iconImg.opacity = 1.0
    }
}