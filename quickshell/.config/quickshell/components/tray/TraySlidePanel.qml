pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../../core"

// Panel con animación slide vertical (sin fade).
Item {
    id: root

    property real panelHeight: 0
    property bool shown: false
    property bool exitRunning: slideOut.running

    default property alias content: inner.data

    clip: true
    height: shown || exitRunning ? Math.max(panelHeight, 1) : 0

    Item {
        id: inner
        width: root.width
        height: Math.max(root.panelHeight, 1)
        y: slideY
    }

    property real slideY: -Math.max(panelHeight, 1)

    onShownChanged: {
        if (shown) {
            if (panelHeight <= 0)
                return
            slideY = -panelHeight
            slideIn.restart()
        } else if (panelHeight > 0) {
            slideOut.restart()
        }
    }

    onPanelHeightChanged: {
        if (shown && panelHeight > 0 && !slideIn.running && slideY < 0)
            slideIn.restart()
    }

    NumberAnimation {
        id: slideIn
        target: root
        property: "slideY"
        from: -Math.max(root.panelHeight, 1)
        to: 0
        duration: 240
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: slideOut
        target: root
        property: "slideY"
        from: root.slideY
        to: -Math.max(root.panelHeight, 1)
        duration: 200
        easing.type: Easing.InCubic
    }
}
