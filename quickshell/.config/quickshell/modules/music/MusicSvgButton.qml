import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: btn

    property int    size:       24
    property string iconPath:   ""
    property int    iconRot:    0
    property bool   btnEnabled: true
    property bool   toggled:    false
    property color  iconColor:  "#ffffff"

    signal clicked()

    readonly property color effectiveColor: btn.btnEnabled
        ? btn.iconColor
        : Qt.rgba(1, 1, 1, 0.32)

    width: size
    height: size
    opacity: !btnEnabled ? 1.0 : (toggled ? 1.0 : (ma.containsMouse ? 0.6 : 1.0))
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Image {
        anchors.centerIn: parent
        width: btn.size * 0.78
        height: btn.size * 0.78
        source: btn.iconPath
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        rotation: btn.iconRot
        cache: true
        asynchronous: true
        layer.enabled: true
        layer.effect: ColorOverlay { color: btn.effectiveColor }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.btnEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (btn.btnEnabled) btn.clicked()
    }
}
