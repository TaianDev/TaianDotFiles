import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../core"
import "../../../components"

PillBase {
    id: root

    property int pacmanCount: 0
    property int aurCount: 0
    property bool checking: false

    Timer {
        interval: 60000 * 30
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: refresh()
    }

    function refresh() {
        checking = true
        pacmanCheck.running = true
        aurCheck.running = true
    }

    onCheckingChanged: {
        if (!checking)
            root.opacity = 1.0
    }

    Process {
        id: pacmanCheck
        command: ["bash", "-c", "checkupdates 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.pacmanCount = parseInt(this.text.trim()) || 0
        }
        onRunningChanged: {
            if (!running && !aurCheck.running)
                root.checking = false
        }
    }

    Process {
        id: aurCheck
        command: ["bash", "-c", "yay -Qum 2>/dev/null | wc -l"]
        stdout: StdioCollector {
            onStreamFinished: root.aurCount = parseInt(this.text.trim()) || 0
        }
        onRunningChanged: {
            if (!running && !pacmanCheck.running)
                root.checking = false
        }
    }

    SequentialAnimation {
        id: pulseAnim
        loops: Animation.Infinite
        running: root.checking
        PropertyAnimation { target: root; property: "opacity"; to: 0.45; duration: 400; easing.type: Easing.InOutQuad }
        PropertyAnimation { target: root; property: "opacity"; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
    }

    content: RowLayout {
        spacing: 6

        SvgIcon {
            source: AppPaths.iconsDir + "ghost.svg"
            size: 14
            tint: Theme.inkSurf
        }

        Text {
            text: root.pacmanCount.toString()
            color: Theme.inkSurf
            font.pixelSize: 12
            font.bold: true
            font.family: "monospace"
        }

        Rectangle {
            width: 1; height: 12
            color: Theme.alpha(Theme.outline, 0.4)
        }

        SvgIcon {
            source: AppPaths.iconsDir + "packages.svg"
            size: 14
            tint: Theme.inkSurf
        }

        Text {
            text: root.aurCount.toString()
            color: Theme.inkSurf
            font.pixelSize: 12
            font.bold: true
            font.family: "monospace"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.refresh()
    }
}
