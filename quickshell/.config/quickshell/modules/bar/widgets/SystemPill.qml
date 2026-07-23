import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../services"

Rectangle {
    id: root
    height: 28
    width: contentRow.implicitWidth + 24
    radius: height / 2
    color: Theme.barPillBackgroundColor()
    border.width: Theme.barPillBorderWidth
    border.color: Theme.barPillBorderColor()

    property int cpuUsage:  SystemMonitorService.cpuUsage
    property int ramUsage:  SystemMonitorService.ramUsage
    property int tempValue: SystemMonitorService.tempValue

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 16

        ResourceMeter {
            value: root.cpuUsage
            iconPath: Qt.resolvedUrl("../../../assets/icons/cpu.svg")
            activeColor: Theme.primary
            suffix: "%"
        }
        ResourceMeter {
            value: root.ramUsage
            iconPath: Qt.resolvedUrl("../../../assets/icons/ram.svg")
            activeColor: Theme.secondary
            suffix: "%"
        }
        ResourceMeter {
            value: root.tempValue
            iconPath: Qt.resolvedUrl("../../../assets/icons/temperature.svg")
            activeColor: Theme.tertiary
            suffix: "°"
        }
    }
}
