pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../core"
import "../../services"
import "."

PanelWindow {
    id: popups

    required property var screen
    property real barPopupTopY: 42

    readonly property var activePopups: {
        const _v = NotificationService.popupVersion
        return NotificationService.popups
    }

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: popups.barPopupTopY
        bottom: 14
        right: 14
    }

    implicitWidth: 340

    color: "transparent"
    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_notif_popups_" + screen.name
    WlrLayershell.layer: WlrLayer.Overlay

    visible: activePopups.length > 0

    Column {
        id: toastColumn
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 10
        width: parent.width

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Repeater {
            model: popups.activePopups

            NotificationPopupToast {
                required property var modelData
                required property int index
                width: toastColumn.width
                notification: modelData
                visible: modelData !== null && modelData !== undefined

                onRequestClose: {
                    if (!modelData)
                        return
                    const transient = modelData?.transient ?? false
                    NotificationService.popPopup(modelData)
                    if (transient)
                        modelData.dismiss()
                }
            }
        }
    }
}
