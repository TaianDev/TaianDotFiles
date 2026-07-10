import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../core"
import "../../services"
import "../../components/shell"

PanelWindow {
    id: launcherPopup
    color: "transparent"

    implicitHeight: 500

    anchors {
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0
    surfaceFormat.opaque: false
    WlrLayershell.namespace: "flare_launcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isOpened: false
    property var allApps: []

    visible: isOpened

    IpcHandler {
        target: "app_launcher"
        function toggle(): void {
            if (launcherPopup.isOpened)
                launcherPopup.isOpened = false
            else {
                PopupManager.openExclusive(PopupManager.launcherId)
                Qt.callLater(() => launcherPopup.isOpened = true)
            }
        }
    }

    Connections {
        target: PopupManager
        function onCloseRequested(id) {
            if (id === PopupManager.launcherId)
                launcherPopup.isOpened = false
        }
    }

    onIsOpenedChanged: {
        if (!isOpened)
            PopupManager.notifyClosed(PopupManager.launcherId)

        if (isOpened) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
        }
    }

    PopupEscCapture {
        active: launcherPopup.isOpened
        popupId: PopupManager.launcherId

        Item {
            anchors.fill: parent

            ConcaveBottomPanel {
            panelWidth: 600
            panelHeight: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                SearchBar {
                    id: searchInput
                    placeholderText: "Search applications..."
                    onTextChanged: filterApps(text)
                    Keys.onUpPressed: {
                        if (appList.currentIndex > 0) {
                            appList.currentIndex--
                            appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                        }
                    }
                    Keys.onDownPressed: {
                        if (appList.currentIndex < filteredModel.count - 1) {
                            appList.currentIndex++
                            appList.positionViewAtIndex(appList.currentIndex, ListView.Contain)
                        }
                    }
                    Keys.onReturnPressed: {
                        const targetIdx = appList.currentIndex >= 0 ? appList.currentIndex : 0
                        if (filteredModel.count > 0)
                            runApp(filteredModel.get(targetIdx).exec)
                    }
                    Keys.onEscapePressed: launcherPopup.isOpened = false
                }

                ListView {
                    id: appList
                    keyNavigationWraps: false
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ListModel { id: filteredModel }
                    clip: true
                    spacing: 6
                    currentIndex: -1
                    interactive: false
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                    delegate: Rectangle {
                        width: appList.width
                        height: 52
                        radius: 12

                        property bool isSelected: appList.currentIndex === index
                        color: isSelected
                               ? Theme.alpha(Theme.primary, 0.18)
                               : (itemMa.containsMouse ? Theme.alpha(Theme.inkSurf, 0.08) : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 16

                            Image {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                source: model.icon.startsWith("/") ? ("file://" + model.icon) : ("image://icon/" + model.icon)
                                sourceSize: Qt.size(28, 28)
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.name
                                color: isSelected ? Theme.primary : Theme.inkSurf
                                font.pixelSize: 14
                                font.bold: isSelected
                            }
                        }

                        MouseArea {
                            id: itemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: runApp(model.exec)
                            onEntered: appList.currentIndex = index
                        }
                    }
                }
            }
        }
        }
    }

    Process {
        id: appScanner
        command: ["bash", "-c", "awk -F= 'BEGIN {IGNORECASE = 1} FNR==1 { if (name != \"\" && no_display != \"true\" && type == \"Application\") { sub(/%[a-zA-Z]/, \"\", exec); print name \"|\" icon \"|\" exec } name=\"\"; icon=\"\"; exec=\"\"; no_display=\"\"; type=\"\" } /^Name=/ && name==\"\" {name=$2} /^Icon=/ && icon==\"\" {icon=$2} /^Exec=/ && exec==\"\" {exec=$2} /^NoDisplay=/ {no_display=tolower($2)} /^Type=/ {type=$2} END { if (name != \"\" && no_display != \"true\" && type == \"Application\") { sub(/%[a-zA-Z]/, \"\", exec); print name \"|\" icon \"|\" exec } }' /usr/share/applications/*.desktop ~/.local/share/applications/*.desktop 2>/dev/null | sort -u -t'|' -k1,1"]

        stdout: StdioCollector {
            onStreamFinished: {
                launcherPopup.allApps = []
                const lines = this.text.trim().split('\n')
                for (let line of lines) {
                    if (!line) continue
                    const parts = line.split('|')
                    if (parts.length >= 3)
                        launcherPopup.allApps.push({ name: parts[0], icon: parts[1], exec: parts[2].trim() })
                }
                filterApps("")
            }
        }
    }

    Component.onCompleted: appScanner.running = true

    function filterApps(query) {
        filteredModel.clear()
        const q = query.toLowerCase()
        for (let app of launcherPopup.allApps) {
            if (app.name.toLowerCase().includes(q))
                filteredModel.append(app)
        }
        appList.currentIndex = -1
    }

    Process {
        id: runner
        property string execCommand: ""
        command: ["hyprctl", "dispatch", "exec", "--", execCommand]
    }

    function runApp(cmd) {
        runner.execCommand = cmd
        runner.running = false
        runner.running = true
        launcherPopup.isOpened = false
    }
}
