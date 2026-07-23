import QtQuick
import "../../core"

Item {
    id: root

    property bool active: false
    property real cornerRadius: 16
    property real borderAlpha: 1
    property color panelColor: Theme.background

    readonly property bool exitRunning: slideOut.running

    default property alias content: inner.data

    anchors.fill: parent
    clip: true

    property real slideY: 0
    property real popupFade: 1.0

    Item {
        id: slideWrap
        width: parent.width
        height: Math.max(parent.height, 1)
        y: root.slideY

        opacity: root.popupFade

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.panelColor
            border.width: 1
            border.color: Theme.alpha(Theme.outlineVariant, root.borderAlpha)
            clip: true

            Item {
                id: inner
                anchors.fill: parent
            }
        }
    }

    onActiveChanged: {
        if (active) {
            slideY = -Math.max(height, 1)
            popupFade = 1.0
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

    SequentialAnimation {
        id: slideIn

        NumberAnimation {
            target: root; property: "slideY"
            from: -Math.max(root.height, 1); to: 0
            duration: 260; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "slideY"
            from: 0; to: -1; duration: 50; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "slideY"
            to: 0; duration: 50; easing.type: Easing.InCubic
        }
    }

    ParallelAnimation {
        id: slideOut

        NumberAnimation {
            target: root; property: "slideY"
            from: 0; to: -Math.max(root.height, 1) * 0.3
            duration: 180; easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root; property: "popupFade"
            from: 1.0; to: 0.0
            duration: 180; easing.type: Easing.InCubic
        }
        onStopped: root.exitFinished()
    }

    signal exitFinished()
}
