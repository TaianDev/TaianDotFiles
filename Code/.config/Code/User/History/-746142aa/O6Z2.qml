import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PopupWindow {
    id: launcherPopup
    color: "transparent"
    
    // 600px para el cuerpo + 40px (20px de cada aleta cóncava)
    implicitWidth: 640
    implicitHeight: 500

    property bool isOpened: false
    property color themeBg: Qt.rgba(0.1, 0.1, 0.12, 0.95)
    property color themeAccent: "#f9e2af" // Amarillo/Dorado premium
    property var allApps: []

    anchor {
        window: null 
        edges: bottom
    }

    onIsOpenedChanged: {
        if (isOpened) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
        }
    }

    // Animación de deslizamiento vertical (Slide)
    Item {
        anchors.fill: parent
        y: launcherPopup.isOpened ? 0 : launcherPopup.implicitHeight
        opacity: launcherPopup.isOpened ? 1 : 0
        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 250 } }

        // Cuerpo Principal del Lanzador
        Rectangle {
            id: mainBody
            width: 600
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 20
            color: launcherPopup.themeBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            // Base recta para un acople perfecto con el borde inferior
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 20
                color: launcherPopup.themeBg
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Buscador de aplicaciones
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    placeholderText: "🔍 Buscar aplicaciones..."
                    color: "#ffffff"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 15
                    
                    background: Rectangle {
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: searchInput.activeFocus ? launcherPopup.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                    }

                    onTextChanged: filterApps(text)
                    
                    // Controles de navegación por teclado
                    Keys.onUpPressed: appList.decrementCurrentIndex()
                    Keys.onDownPressed: appList.incrementCurrentIndex()
                    Keys.onReturnPressed: {
                        let targetIdx = appList.currentIndex >= 0 ? appList.currentIndex : 0
                        if (filteredModel.count > 0) {
                            runApp(filteredModel.get(targetIdx).exec)
                        }
                    }
                    Keys.onEscapePressed: launcherPopup.isOpened = false
                }

                // Lista de resultados
                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ListModel { id: filteredModel }
                    clip: true
                    spacing: 6
                    currentIndex: -1
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

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
                            
                            Button {
                                Layout.preferredWidth: 28
                                Layout.preferredHeight: 28
                                icon.name: model.icon
                                icon.width: 28
                                icon.height: 28
                                background: Item {} 
                                enabled: false 
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

        // Esquina Cóncava Izquierda
        Shape {
            anchors.bottom: parent.bottom
            anchors.right: mainBody.left
            width: 20; height: 20
            antialiasing: true; layer.enabled: true; layer.samples: 8
            ShapePath {
                fillColor: launcherPopup.themeBg
                strokeWidth: 0
                startX: 20; startY: 0
                PathLine { x: 20; y: 20 }
                PathLine { x: 0; y: 20 }
                PathQuad { x: 20; y: 0; controlX: 20; controlY: 20 }
            }
        }

        // Esquina Cóncava Derecha
        Shape {
            anchors.bottom: parent.bottom
            anchors.left: mainBody.right
            width: 20; height: 20
            antialiasing: true; layer.enabled: true; layer.samples: 8
            ShapePath {
                fillColor: launcherPopup.themeBg
                strokeWidth: 0
                startX: 0; startY: 0
                PathLine { x: 0; y: 20 }
                PathLine { x: 20; y: 20 }
                PathQuad { x: 0; y: 0; controlX: 0; controlY: 20 }
            }
        }
    }

    // Parser optimizado de archivos .desktop del sistema
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

    // Gestor de ejecución de procesos desvinculados
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