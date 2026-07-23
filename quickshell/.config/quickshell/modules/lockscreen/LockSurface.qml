import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property LockContext context

    property string homeDir: ""
    readonly property string iconPathBase: homeDir !== ""
        ? "file://" + homeDir + "/.config/quickshell/assets/icons/"
        : ""
    property string userName: ""
    property string wallpaperPath: ""

    function alpha(c, o) { return Qt.rgba(c.r, c.g, c.b, o) }
    function formatTime(seconds) {
        var m = Math.floor(seconds / 60)
        var s = seconds % 60
        return m.toString().padStart(2, '0') + ":" + s.toString().padStart(2, '0')
    }

    property bool capsLockOn: false
    property int failedAttempts: 0
    property int lockoutRemaining: 0
    property bool lockedOut: false
    property bool attemptMade: false

    // ═══════════════════════════════════════════════════════════
    // WALLPAPER BACKGROUND
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        anchors.fill: parent
        color: Theme.primaryContainer
    }

    Item {
        id: wallpaperLayer
        anchors.fill: parent

        Image {
            id: wallpaperImg
            anchors.fill: parent
            source: root.wallpaperPath !== "" ? "file://" + root.wallpaperPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        FastBlur {
            anchors.fill: wallpaperImg
            source: wallpaperImg
            radius: 64
        }

        BubbleField {
            anchors.fill: parent
            palette: [
                alpha(Theme.primary, 0.28),
                alpha(Theme.secondary, 0.22),
                alpha(Theme.tertiary, 0.18),
                alpha(Theme.primary, 0.16),
            ]
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
        }
    }

    Process {
        id: wallpaperQuery
        command: ["swww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split('\n')
                for (const line of lines) {
                    const idx = line.indexOf("image: ")
                    if (idx >= 0) {
                        root.wallpaperPath = line.substring(idx + 7).trim()
                        break
                    }
                }
            }
        }
    }

    Process {
        id: userResolver
        command: ["sh", "-c", "echo -n \"$USER\""]
        stdout: StdioCollector {
            onStreamFinished: root.userName = this.text.trim()
        }
    }

    Process {
        id: homeResolver
        command: ["sh", "-c", "echo -n \"$HOME\""]
        stdout: StdioCollector {
            onStreamFinished: root.homeDir = this.text.trim()
        }
    }

    Process {
        id: capsLockChecker
        command: ["bash", "-c", "xset -q | grep -qi 'caps lock.*on' && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: root.capsLockOn = this.text.trim() === "on"
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: capsLockChecker.running = true
    }

    Timer {
        id: lockoutTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            root.lockoutRemaining--
            if (root.lockoutRemaining <= 0) {
                root.lockoutRemaining = 0
                root.lockedOut = false
                root.failedAttempts = 0
                running = false
                passwordBox.focus = true
            }
        }
    }

    // ═══════════════════════════════════════════════════════════
    // MAIN CONTENT
    // ═══════════════════════════════════════════════════════════
    Item {
        id: contentArea
        anchors.fill: parent

        // ── CLOCK ──
        Text {
            id: clockText
            property var date: new Date()

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: parent.height * 0.10
            }

            renderType: Text.NativeRendering
            font.pixelSize: 96
            font.weight: Font.Light
            color: Theme.onPrimaryContainer

            Timer {
                running: true
                repeat: true
                interval: 1000
                onTriggered: clockText.date = new Date()
            }

            text: {
                const h = clockText.date.getHours().toString().padStart(2, '0')
                const m = clockText.date.getMinutes().toString().padStart(2, '0')
                return h + ":" + m
            }
        }

        // ── DATE ──
        Text {
            id: dateText
            property var date: new Date()

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: clockText.bottom
                topMargin: 6
            }

            renderType: Text.NativeRendering
            font.pixelSize: 22
            font.weight: Font.Normal
            color: alpha(Theme.onPrimaryContainer, 0.65)

            Timer {
                running: true
                repeat: true
                interval: 60000
                onTriggered: dateText.date = new Date()
            }

            text: {
                const d = dateText.date
                const days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                const months = ["January","February","March","April","May","June","July","August",
                    "September","October","November","December"]
                return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
            }
        }

        // ── GREETING ──
        Text {
            id: greetingText
            property var date: new Date()

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: dateText.bottom
                topMargin: 24
            }

            renderType: Text.NativeRendering
            font.pixelSize: 18
            font.weight: Font.Normal
            color: alpha(Theme.onPrimaryContainer, 0.7)

            Timer {
                running: true
                repeat: true
                interval: 60000
                onTriggered: greetingText.date = new Date()
            }

            text: {
                const h = greetingText.date.getHours()
                if (h >= 5 && h < 12) return "Good morning"
                if (h >= 12 && h < 18) return "Good afternoon"
                if (h >= 18 && h < 22) return "Good evening"
                return "Good night"
            }
        }

        // ── PASSWORD SECTION ──
        Item {
            id: passwordSection
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: greetingText.bottom
                topMargin: 32
            }
            width: passwordRow.width
            height: passwordRow.height
                + (errorText.visible ? errorText.height + 10 : 0)
                + (root.capsLockOn ? capsLockIndicator.height + 6 : 0)
                + (root.lockedOut ? lockoutText.height + 6 : 0)

            Row {
                id: passwordRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                TextField {
                    id: passwordBox
                    implicitWidth: 300
                    padding: 14
                    focus: true
                    enabled: !root.context.unlockInProgress && !root.lockedOut
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    color: Theme.onBackground
                    font.pixelSize: 16

                    placeholderText: root.lockedOut ? "" : "Enter password"
                    placeholderTextColor: alpha(Theme.onBackgroundMuted, 0.42)

                    background: Rectangle {
                        radius: 16
                        color: alpha(Theme.surface, 0.55)
                        border.width: 1.5
                        border.color: root.context.showFailure
                            ? Theme.error
                            : (passwordBox.activeFocus ? Theme.primary : alpha(Theme.outline, 0.22))
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    onTextChanged: root.context.currentText = this.text
                    onAccepted: root.context.tryUnlock()

                    Connections {
                        target: root.context
                        function onCurrentTextChanged() {
                            passwordBox.text = root.context.currentText
                        }
                    }
                }

                Rectangle {
                    id: unlockBtn
                    width: 48
                    height: 48
                    radius: 16
                    color: unlockMa.containsMouse && !root.context.unlockInProgress
                        ? Theme.primaryContainer : Theme.primary
                    opacity: (root.context.currentText !== "" && !root.context.unlockInProgress) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                        anchors.centerIn: parent
                        source: root.iconPathBase + "lock.svg"
                        width: 22
                        height: 22
                        sourceSize.width: 22
                        sourceSize.height: 22
                        fillMode: Image.PreserveAspectFit
                        cache: true
                        layer.enabled: true
                        layer.effect: ColorOverlay { color: Theme.onPrimary }
                    }

                    MouseArea {
                        id: unlockMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.context.currentText !== "" && !root.context.unlockInProgress
                            ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (root.context.currentText !== "" && !root.context.unlockInProgress)
                                root.context.tryUnlock()
                        }
                    }
                }
            }

            Text {
                id: errorText
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: passwordRow.bottom
                    topMargin: 10
                }
                visible: root.context.showFailure
                text: root.failedAttempts > 0
                    ? "Incorrect password (" + root.failedAttempts + "/3)"
                    : "Incorrect password"
                color: Theme.error
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            Text {
                id: capsLockIndicator
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: errorText.visible ? errorText.bottom : passwordRow.bottom
                    topMargin: 6
                }
                visible: root.capsLockOn && !root.lockedOut
                text: "⇪ Caps Lock is on"
                color: alpha(Theme.onBackground, 0.45)
                font.pixelSize: 11
                font.weight: Font.Normal
            }

            Text {
                id: lockoutText
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: capsLockIndicator.visible ? capsLockIndicator.bottom : (
                        errorText.visible ? errorText.bottom : passwordRow.bottom
                    )
                    topMargin: 6
                }
                visible: root.lockedOut
                text: "Too many attempts — wait " + formatTime(root.lockoutRemaining)
                color: alpha(Theme.error, 0.8)
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        // ── MUSIC PLAYER ──
        LockMusicPlayer {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: passwordSection.bottom
                topMargin: 72
            }
        }

        // ── BOTTOM-LEFT: SESSION USER ──
        UserPill {
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 36
            }
            iconsPath: root.iconPathBase
            userName: root.userName
        }

        // ── BOTTOM-RIGHT: POWER MENU ──
        LockPowerMenu {
            anchors.fill: parent
        }
    }

    // ═══════════════════════════════════════════════════════════
    // WAVE OVERLAY (entry / exit animations)
    // ═══════════════════════════════════════════════════════════
    Rectangle {
        id: waveOverlay
        anchors { left: parent.left; right: parent.right }
        height: parent.height
        y: 0
        z: 9999

        property bool exitMode: false
        color: Theme.primaryContainer

        Rectangle {
            id: waveEdgeBottom
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: parent.height * 0.15
            visible: !waveOverlay.exitMode

            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.primaryContainer }
                GradientStop { position: 0.25; color: alpha(Theme.primaryContainer, 0.82) }
                GradientStop { position: 0.6; color: alpha(Theme.primaryContainer, 0.28) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            id: waveEdgeTop
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: parent.height * 0.15
            visible: waveOverlay.exitMode

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.4; color: alpha(Theme.primaryContainer, 0.28) }
                GradientStop { position: 0.75; color: alpha(Theme.primaryContainer, 0.82) }
                GradientStop { position: 1.0; color: Theme.primaryContainer }
            }
        }
    }

    // ── ANIMATIONS ──
    NumberAnimation {
        id: enterAnim
        target: waveOverlay
        property: "y"
        from: 0
        to: root.height || 1080
        duration: 700
        easing.type: Easing.InOutCubic
    }

    NumberAnimation {
        id: exitAnim
        target: waveOverlay
        property: "y"
        from: root.height || 1080
        to: 0
        duration: 500
        easing.type: Easing.InOutCubic
    }

    Component.onCompleted: {
        wallpaperQuery.running = true
        userResolver.running = true
        homeResolver.running = true
        capsLockChecker.running = true
        enterAnim.start()
    }

    Connections {
        target: context
        function onUnlocked() {
            root.failedAttempts = 0
            root.lockedOut = false
            root.lockoutRemaining = 0
            lockoutTimer.running = false
            waveOverlay.exitMode = true
            waveOverlay.y = root.height || 1080
            exitAnim.start()
        }
    }

    Connections {
        target: context
        function onShowFailureChanged() {
            if (context.showFailure) {
                root.failedAttempts++
                root.attemptMade = true
                if (root.failedAttempts >= 3) {
                    root.lockedOut = true
                    root.lockoutRemaining = 300
                    lockoutTimer.running = true
                }
            }
        }
    }
}
