import QtQuick
import "../../services"

// Content wrapper for bar popups. Escape is handled by PopupManager (hyprctl bind).
Item {
    id: root

    required property bool active
    required property string popupId

    default property alias content: contentHost.data

    anchors.fill: parent

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
