import QtQuick
import "../../core"

// Contenedor con animación slide vertical (sin fade) para popups secundarios.
Item {
    id: root

    property bool active: false
    property real cornerRadius: 16
    property color panelColor: Theme.background
    property int originH: Item.Center
    property int originV: Item.Top

    readonly property bool exitRunning: slideOut.running

    default property alias content: inner.data

    anchors.fill: parent
    clip: true

    Item {
        id: slideWrap
        width: parent.width
        height: Math.max(parent.height, 1)
        y: slideY

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.panelColor
            border.width: 1
            border.color: Theme.outlineVariant
            clip: true

            Item {
                id: inner
                anchors.fill: parent
            }
        }
    }

    property real slideY: -Math.max(height, 1)

    onActiveChanged: {
        if (active) {
            slideY = -Math.max(height, 1)
            if (height > 0)
                slideIn.restart()
        } else if (height > 0) {
            slideOut.restart()
        }
    }

    onHeightChanged: {
        if (active && height > 0 && slideY < 0 && !slideIn.running)
            slideIn.restart()
    }

    NumberAnimation {
        id: slideIn
        target: root
        property: "slideY"
        from: -Math.max(root.height, 1)
        to: 0
        duration: 240
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: slideOut
        target: root
        property: "slideY"
        from: root.slideY
        to: -Math.max(root.height, 1)
        duration: 200
        easing.type: Easing.InCubic
        onStopped: root.exitFinished()
    }

    signal exitFinished()
}
