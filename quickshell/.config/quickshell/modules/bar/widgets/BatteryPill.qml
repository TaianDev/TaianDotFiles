import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../core"
import "../../../services"

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../../assets/icons/")

    property int capacity: SystemMonitorService.capacity
    property string status: SystemMonitorService.status
    property bool acOnline: SystemMonitorService.acOnline

    readonly property bool plugged: root.acOnline || root.status === "Charging"
                                    || root.status === "Full"
    readonly property bool showThunder: root.plugged
    readonly property int level: Math.min(5, Math.floor(root.capacity / 100 * 6))
    readonly property real fillRatio: Math.max(0, Math.min(1, root.capacity / 100))
    readonly property string iconFile: root.showThunder
        ? "thunder.svg"
        : ("battery-" + root.level + ".svg")

    implicitWidth: Math.max(48, contentRow.implicitWidth + 24)
    implicitHeight: 28

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.barPillBackgroundColor()
        border.width: Theme.barPillBorderWidth
        border.color: Theme.barPillBorderColor()
        clip: true

        Rectangle {
            id: fillBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: track.width * root.fillRatio
            topLeftRadius: track.height / 2
            bottomLeftRadius: track.height / 2
            topRightRadius: root.fillRatio >= 1 ? track.height / 2 : 0
            bottomRightRadius: root.fillRatio >= 1 ? track.height / 2 : 0
            color: root.showThunder
                   ? Theme.alpha(Theme.primary, 0.42)
                   : (root.level <= 1
                      ? Theme.alpha(Theme.err, 0.38)
                      : Theme.alpha(Theme.primary, 0.30))

            Behavior on width {
                NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
            }
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        SvgIcon {
            source: root.iconsPath + root.iconFile
            size: 14
            tint: Theme.inkSurf
        }

        Text {
            text: root.capacity.toString()
            color: Theme.inkSurf
            font.pixelSize: 12
            font.bold: true
            font.family: "monospace"
        }
    }
}
