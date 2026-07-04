import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

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
    WlrLayershell.namespace: "launcher_app"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isOpened: false
    property color themeBg: "#1a1a1e" 
    property color themeAccent: "#f9e2af"
    property var allApps: []

    visible: isOpened

    onIsOpenedChanged: {
        if (isOpened) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        // 🌟 Cuerpo Principal Unificado (Ahora es un Item, no un Rectangle)
        Item {
            id: mainBody
            width: 600
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            // 🌟 FORMA VECTORIAL CONTINUA (Fondo + Borde sin costuras)
            Shape {
                anchors.fill: parent
                // Expandimos la forma 20px a cada lado para que quepan las aletas cóncavas
                anchors.leftMargin: -20
                anchors.rightMargin: -20
                antialiasing: true
                layer.enabled: true
                layer.samples: 8

                // 1. PATH DE RELLENO (Todo el color, sin borde)
                ShapePath {
                    fillColor: launcherPopup.themeBg
                    strokeWidth: 0

                    startX: 0; startY: mainBody.height
                    // Aleta cóncava izquierda
                    PathQuad { x: 20; y: mainBody.height - 20; controlX: 20; controlY: mainBody.height }
                    // Pared izquierda
                    PathLine { x: 20; y: 20 }
                    // Esquina superior izquierda
                    PathArc { x: 40; y: 0; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    // Techo
                    PathLine { x: 600; y: 0 }
                    // Esquina superior derecha
                    PathArc { x: 620; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    // Pared derecha
                    PathLine { x: 620; y: mainBody.height - 20 }
                    // Aleta cóncava derecha
                    PathQuad { x: 640; y: mainBody.height; controlX: 620; controlY: mainBody.height }
                    // Cerrar el relleno en la base
                    PathLine { x: 0; y: mainBody.height } 
                }

                // 2. PATH DE BORDE (Solo la línea, sin relleno, abierto por la base)
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.rgba(1, 1, 1, 0.1)
                    strokeWidth: 1

                    startX: 0; startY: mainBody.height
                    PathQuad { x: 20; y: mainBody.height - 20; controlX: 20; controlY: mainBody.height }
                    PathLine { x: 20; y: 20 }
                    PathArc { x: 40; y: 0; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 600; y: 0 }
                    PathArc { x: 620; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 620; y: mainBody.height - 20 }
                    PathQuad { x: 640; y: mainBody.height; controlX: 620; controlY: mainBody.height }
                    // 🌟 Nota: No cerramos la forma aquí para que no dibuje una línea recta en la parte inferior
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: "🔍 Buscar aplicaciones..."
                    color: "#ffffff"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 15
                    activeFocusOnPress: false 
                    
                    background: Rectangle {
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: searchInput.activeFocus ? launcherPopup.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                    }

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
                        let targetIdx = appList.currentIndex >= 0 ? appList.currentIndex : 0
                        if (filteredModel.count > 0) {
                            runApp(filteredModel.get(targetIdx).exec)
                        }
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
                        color: isSelected ? Qt.rgba(0.97, 0.88, 0.68, 0.15) : (itemMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                        
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
                                color: isSelected ? launcherPopup.themeAccent : "#ffffff"
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
                    if (parts.length >= 3) {
                        launcherPopup.allApps.push({ name: parts[0], icon: parts[1], exec: parts[2].trim() })
                    }
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
            if (app.name.toLowerCase().includes(q)) filteredModel.append(app)
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