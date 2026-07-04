import QtQuick
import QtQuick.Layouts

Item {
    id: moduleWrapper

    // Propiedades inyectables desde el padre
    property bool isPinned: false
    property bool moduleAvailable: true
    property bool groupExpanded: false       // Se conecta al estado expandido del grupo
    property color themeFg: "#ffffff"       // Color principal del tema

    // Contenido interno (el módulo real, como Wifi, Audio, etc.)
    default property alias moduleData: container.data

    readonly property bool shouldBeActive: (groupExpanded || isPinned) && moduleAvailable

    property int targetHeight: shouldBeActive ? 38 : 0
    Behavior on targetHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    // Propiedades de Layout para usar dentro de ColumnLayout/RowLayout
    Layout.preferredWidth: shouldBeActive ? 38 : 0
    Layout.preferredHeight: targetHeight
    Layout.alignment: Qt.AlignHCenter

    visible: targetHeight > 0
    opacity: targetHeight / 38
    width: 38
    height: 38

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: "transparent"
        border.width: isPinned && groupExpanded ? 1 : 0
        border.color: themeFg
    }

    Item {
        id: container
        width: 32
        height: 32
        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                moduleWrapper.isPinned = !moduleWrapper.isPinned
            }
        }
    }
}