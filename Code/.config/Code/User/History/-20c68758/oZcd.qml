import QtQuick
import Quickshell

Rectangle {
    id: btn
    width: 32
    height: 32
    color: "transparent"
    radius: 6

    // Propiedades personalizables
    property color iconColor: "#ffffff"
    property string iconName: "screenshot_region"
    property int iconSize: 22

    Text {
        anchors.centerIn: parent
        text: btn.iconName
        font.family: "Material Symbols Outlined"
        font.pixelSize: btn.iconSize
        color: btn.iconColor
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached([
                "bash", "-c",
                "grim -g \"$(slurp)\" -t ppm - | satty --filename -"
            ]);
        }
    }
}