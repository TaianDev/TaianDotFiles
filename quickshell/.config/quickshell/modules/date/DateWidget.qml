import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../core"
import "../../services"
import "../../components"
import "../../utils"

Rectangle {
    id: root

    height: 28
    implicitWidth: mainLayout.width + 24
    radius: height / 2
    color: widgetMa.containsMouse
        ? Theme.alpha(Theme.surfaceVariant, 0.72)
        : Theme.barPillBackgroundColor()
    border.width: Theme.barPillBorderWidth
    border.color: Theme.barPillBorderColor()
    Behavior on color { ColorAnimation { duration: 150 } }

    property string tempString: "..."
    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property var hostWindow: null

    property int activeInstance: 1
    property string currentViewState: tmEndedNotification ? "notification"
        : showSwControls ? "stopwatch"
        : showTmControls ? "timer" : "normal"

    property bool swRunning: false
    property int swElapsedMs: 0
    property bool showSwControls: false

    Timer {
        id: swTimer
        interval: 50; running: root.swRunning; repeat: true
        onTriggered: root.swElapsedMs += 50
    }

    property int tmH: 0
    property int tmM: 0
    property int tmS: 0
    property int tmTotalSecs: 0
    property bool tmActive: false
    property bool tmRunning: false
    property bool tmEndedNotification: false
    property bool showTmControls: false

    Timer {
        id: tmTimer
        interval: 1000; running: root.tmRunning; repeat: true
        onTriggered: {
            if (root.tmTotalSecs > 0) root.tmTotalSecs--
            else { root.tmRunning = false; root.tmActive = false; root.triggerTimerEnded() }
        }
    }

    Timer {
        id: dismissNotificationTimer
        interval: 5000
        onTriggered: root.tmEndedNotification = false
    }

    function triggerTimerEnded() {
        root.showTmControls = false; root.showSwControls = false
        root.tmEndedNotification = true; dismissNotificationTimer.restart()
    }

    Timer { id: autoHideSw; interval: 3500; onTriggered: root.showSwControls = false }
    Timer { id: autoHideTm; interval: 3500; onTriggered: root.showTmControls = false }

    onSwRunningChanged: {
        if (swRunning) { root.activeInstance = 1; root.showSwControls = true; root.showTmControls = false; autoHideSw.restart() }
    }
    onTmRunningChanged: {
        if (tmRunning) { root.activeInstance = 2; root.showTmControls = true; root.showSwControls = false; autoHideTm.restart() }
    }

    SystemClock { id: sysClock; precision: SystemClock.Minutes }

    Process {
        id: weatherScanner
        command: ["bash", "-c", "curl -s 'wttr.in/Lima?format=%c%t' | tr -d '+' | sed 's/  */ /g'"]
        stdout: StdioCollector {
            onStreamFinished: { let temp = this.text.trim(); if (temp !== "") root.tempString = temp }
        }
    }
    Timer {
        interval: 1800000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { weatherScanner.running = false; weatherScanner.running = true }
    }

    MouseArea {
        id: widgetMa
        anchors.fill: parent
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        property real startX: 0
        property bool dragDetected: false

        onPressed: mouse => { startX = mouse.x; dragDetected = false }

        onPositionChanged: mouse => {
            if (!dragDetected && (mouse.x - startX > 40)) {
                dragDetected = true
                let swIsActive = (root.swElapsedMs > 0 || root.swRunning)
                if (swIsActive && root.tmActive) {
                    root.activeInstance = (root.activeInstance === 1) ? 2 : 1
                    if (root.showSwControls || root.showTmControls) {
                        root.showSwControls = (root.activeInstance === 1)
                        root.showTmControls = (root.activeInstance === 2)
                    }
                }
            }
        }

        onClicked: mouse => {
            if (dragDetected) return
            if (mouse.button === Qt.RightButton) {
                if (datePopup.isOpened) {
                    datePopup.isOpened = false
                } else {
                    PopupManager.openExclusive(PopupManager.dateId)
                    Qt.callLater(() => datePopup.isOpened = true)
                }
            } else {
                if (root.tmEndedNotification) { root.tmEndedNotification = false; return }
                if (root.activeInstance === 1 && (root.swElapsedMs > 0 || root.swRunning)) {
                    root.showSwControls = !root.showSwControls; root.showTmControls = false; autoHideSw.stop()
                } else if (root.activeInstance === 2 && root.tmActive) {
                    root.showTmControls = !root.showTmControls; root.showSwControls = false; autoHideTm.stop()
                }
            }
        }
    }

    Item {
        id: mainLayout
        anchors.centerIn: parent
        height: 28

        width: currentViewState === "notification" ? notificationView.implicitWidth
            : currentViewState === "stopwatch" ? swView.implicitWidth
            : currentViewState === "timer" ? tmView.implicitWidth : normalView.implicitWidth
        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.4 } }

        RowLayout {
            id: normalView
            anchors.centerIn: parent
            opacity: root.currentViewState === "normal" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 8

            RowLayout {
                spacing: 6
                visible: root.swElapsedMs > 0 || root.tmActive

                Rectangle {
                    id: swDotIndicator
                    width: 8; height: 8; radius: 4; color: Theme.err
                    visible: root.swElapsedMs > 0
                    SequentialAnimation {
                        id: swDotBlinker
                        running: root.swRunning && root.currentViewState === "normal" && swDotIndicator.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: swDotIndicator; property: "opacity"; from: 1; to: 0.2; duration: 600 }
                        NumberAnimation { target: swDotIndicator; property: "opacity"; from: 0.2; to: 1; duration: 600 }
                        onRunningChanged: { if (!running) swDotIndicator.opacity = 1 }
                    }
                }

                Item {
                    id: tmIconIndicator
                    Layout.preferredWidth: 12; Layout.preferredHeight: 12
                    visible: root.tmActive
                    Image {
                        anchors.fill: parent; source: root.iconsPath + "sand-clock.svg"
                        sourceSize.width: 12; sourceSize.height: 12
                        fillMode: Image.PreserveAspectFit
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: Theme.inkSurf }
                    }
                    SequentialAnimation {
                        id: tmIconBlinker
                        running: root.tmRunning && root.currentViewState === "normal" && tmIconIndicator.visible
                        loops: Animation.Infinite
                        NumberAnimation { target: tmIconIndicator; property: "opacity"; from: 1; to: 0.3; duration: 600 }
                        NumberAnimation { target: tmIconIndicator; property: "opacity"; from: 0.3; to: 1; duration: 600 }
                        onRunningChanged: { if (!running) tmIconIndicator.opacity = 1 }
                    }
                }
            }

            Text {
                // Usamos Qt.formatDateTime para aplicar tus patrones personalizados correctamente
                text: Qt.formatDateTime(sysClock.date, "HH:mm") + " \u2022 " + 
                    Qt.formatDateTime(sysClock.date, "ddd, dd/MM") + " \u2022 " + root.tempString
                color: Theme.inkSurf
                font.pixelSize: 12
                font.bold: true
            }
        }

        RowLayout {
            id: swView
            anchors.centerIn: parent
            opacity: root.currentViewState === "stopwatch" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 12

            Rectangle {
                id: swActiveDot
                width: 8; height: 8; radius: 4; color: Theme.err
                SequentialAnimation {
                    running: root.swRunning && root.currentViewState === "stopwatch"
                    loops: Animation.Infinite
                    NumberAnimation { target: swActiveDot; property: "opacity"; from: 1; to: 0.2; duration: 600 }
                    NumberAnimation { target: swActiveDot; property: "opacity"; from: 0.2; to: 1; duration: 600 }
                    onRunningChanged: { if (!running) swActiveDot.opacity = 1 }
                }
            }

            Text {
                text: TimeUtils.formatMSS(root.swElapsedMs)
                color: Theme.inkSurf; font.pixelSize: 14; font.bold: true; font.family: "monospace"
            }

            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(1, 1, 1, 0.1)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + "stop.svg"; size: 12; tint: Theme.inkSurf }
                MouseArea { anchors.fill: parent; onClicked: { root.swRunning = false; root.swElapsedMs = 0; root.showSwControls = false } }
            }
            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(224/255, 108/255, 117/255, 0.2)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + (root.swRunning ? "pause.svg" : "play.svg"); size: 12; tint: Theme.err }
                MouseArea { anchors.fill: parent; onClicked: root.swRunning = !root.swRunning }
            }
        }

        RowLayout {
            id: tmView
            anchors.centerIn: parent
            opacity: root.currentViewState === "timer" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 12

            Image {
                source: root.iconsPath + "sand-clock.svg"
                Layout.preferredWidth: 14; Layout.preferredHeight: 14
                sourceSize.width: 14; sourceSize.height: 14
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: Theme.inkSurf }
            }

            Text {
                text: TimeUtils.formatHMSSecs(root.tmTotalSecs)
                color: Theme.inkSurf; font.pixelSize: 14; font.bold: true; font.family: "monospace"
            }

            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(1, 1, 1, 0.1)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + "stop.svg"; size: 12; tint: Theme.inkSurf }
                MouseArea { anchors.fill: parent; onClicked: { root.tmRunning = false; root.tmActive = false; root.tmTotalSecs = 0; root.showTmControls = false } }
            }
            Rectangle { width: 24; height: 24; radius: 6; color: Qt.rgba(180/255, 219/255, 146/255, 0.2)
                SvgIcon { anchors.centerIn: parent; source: root.iconsPath + (root.tmRunning ? "pause.svg" : "play.svg"); size: 12; tint: Theme.primary }
                MouseArea { anchors.fill: parent; onClicked: root.tmRunning = !root.tmRunning }
            }
        }

        RowLayout {
            id: notificationView
            anchors.centerIn: parent
            opacity: root.currentViewState === "notification" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            spacing: 10

            Image {
                source: root.iconsPath + "end-clock.svg"
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                sourceSize.width: 16; sourceSize.height: 16
                fillMode: Image.PreserveAspectFit
                layer.enabled: true
                layer.effect: ColorOverlay { color: Theme.inkSurf }
            }

            Text { text: "Time's up!"; color: Theme.err; font.pixelSize: 14; font.bold: true }
        }
    }

    function togglePopup() {
        if (datePopup.isOpened) { datePopup.isOpened = false }
        else { PopupManager.openExclusive(PopupManager.dateId); Qt.callLater(() => datePopup.isOpened = true) }
    }

    Item {
        id: timerKeyBridge
        focus: datePopup.isOpened && datePopup.currentTab === 2
        Keys.onPressed: event => {
            const popup = datePopup
            if (!popup || popup.currentTab !== 2) return
            const tt = popup.timerTabInstance
            if (!tt) return
            if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) tt.backspaceField()
            else {
                const ch = event.text
                if (ch >= "0" && ch <= "9") tt.appendDigit(parseInt(ch, 10))
            }
        }
    }

    DatePopup {
        id: datePopup
        widgetRef: root
        anchorItem: root
        parentWindow: root.hostWindow
    }
}
