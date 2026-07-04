import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: themeChanger
    color: "transparent"
    
    // Altura del panel
    implicitHeight: 450
    
    anchors {
        bottom: true
        left: true
        right: true
    }
    
    exclusiveZone: 0 
    WlrLayershell.namespace: "theme_changer"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isOpened: false
    property color themeBg: "#1a1a1e" 
    property color themeAccent: "#f9e2af"
    property var allWallpapers: []
    property string activeWallpaperPath: ""

    // ─── COMUNICACIÓN IPC ───
    IpcHandler {
        target: "theme_panel"
        function toggle(): void {
            themeChanger.isOpened = !themeChanger.isOpened
        }
    }

    visible: isOpened

    onIsOpenedChanged: {
        if (isOpened) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
            wallScanner.running = true
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        // 🌟 CUERPO PRINCIPAL UNIFICADO (Misma lógica que AppLauncher)
        Item {
            id: mainBody
            width: 900 // Más ancho que el AppLauncher para acomodar el carrusel
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

            // 🌟 FORMA VECTORIAL CÓNCAVA
            Shape {
                anchors.fill: parent
                anchors.leftMargin: -20
                anchors.rightMargin: -20
                antialiasing: true
                layer.enabled: true
                layer.samples: 8

                // 1. PATH DE RELLENO
                ShapePath {
                    fillColor: themeChanger.themeBg
                    strokeWidth: 0

                    startX: 0; startY: mainBody.height
                    PathQuad { x: 20; y: mainBody.height - 20; controlX: 20; controlY: mainBody.height }
                    PathLine { x: 20; y: 20 }
                    PathArc { x: 40; y: 0; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 900; y: 0 }
                    PathArc { x: 920; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 920; y: mainBody.height - 20 }
                    PathQuad { x: 940; y: mainBody.height; controlX: 920; controlY: mainBody.height }
                    PathLine { x: 0; y: mainBody.height } 
                }

                // 2. PATH DE BORDE (Línea sin base)
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.rgba(1, 1, 1, 0.1)
                    strokeWidth: 1

                    startX: 0; startY: mainBody.height
                    PathQuad { x: 20; y: mainBody.height - 20; controlX: 20; controlY: mainBody.height }
                    PathLine { x: 20; y: 20 }
                    PathArc { x: 40; y: 0; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 900; y: 0 }
                    PathArc { x: 920; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 920; y: mainBody.height - 20 }
                    PathQuad { x: 940; y: mainBody.height; controlX: 920; controlY: mainBody.height }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 20

                // ─── CARRUSEL HORIZONTAL ───
                ListView {
                    id: wallList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 16
                    model: ListModel { id: filteredModel }
                    clip: true
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    delegate: Item {
                        width: 180
                        // Usar ListView.view.height garantiza que no colapse a 0 px de alto
                        height: ListView.view.height 
                        
                        property bool isActive: model.path === themeChanger.activeWallpaperPath

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            clip: true
                            border.width: isActive ? 2 : (itemMa.containsMouse ? 1 : 0)
                            border.color: isActive ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.3)
                            
                            scale: itemMa.containsMouse && !isActive ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Image {
                                anchors.fill: parent
                                source: "file://" + model.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(200, 400) 
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 40
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.9) }
                                }
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 8
                                width: parent.width - 16
                                text: model.name
                                color: "#ffffff"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    themeChanger.activeWallpaperPath = model.path
                                    applyWallpaper(model.path)
                                }
                            }
                        }
                    }
                }

                // ─── BARRA DE BÚSQUEDA ───
                TextField {
                    id: searchInput
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 500
                    Layout.preferredHeight: 48
                    
                    placeholderText: "🔍 Buscar fondos..."
                    color: "#ffffff"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 15
                    activeFocusOnPress: false 
                    
                    background: Rectangle {
                        radius: 14
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: searchInput.activeFocus ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                    }

                    onTextChanged: filterWallpapers(text)
                    Keys.onEscapePressed: themeChanger.isOpened = false
                    
                    Keys.onRightPressed: {
                        if (wallList.currentIndex < filteredModel.count - 1) {
                            wallList.currentIndex++
                            wallList.positionViewAtIndex(wallList.currentIndex, ListView.Contain)
                        }
                    }
                    Keys.onLeftPressed: {
                        if (wallList.currentIndex > 0) {
                            wallList.currentIndex--
                            wallList.positionViewAtIndex(wallList.currentIndex, ListView.Contain)
                        }
                    }
                    Keys.onReturnPressed: {
                        let targetIdx = wallList.currentIndex >= 0 ? wallList.currentIndex : 0
                        if (filteredModel.count > 0) {
                            applyWallpaper(filteredModel.get(targetIdx).path)
                        }
                    }
                }
            }
        }
    }

    // ─── BACKEND SCANNER ───
    Process {
        id: wallScanner
        // 🌟 CORRECCIÓN: Usamos $HOME explícitamente para evitar fallos de evaluación de ruta
        command: ["bash", "-c", "find \"$HOME/Imágenes/Fondos\" -maxdepth 1 -type f \\( -iname \\*.jpg -o -iname \\*.png -o -iname \\*.jpeg -o -iname \\*.webp \\) | sort"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                let tempWallpapers = []
                const lines = this.text.trim().split('\n')
                for (let line of lines) {
                    if (!line) continue
                    let fileName = line.substring(line.lastIndexOf('/') + 1)
                    tempWallpapers.push({ path: line, name: fileName })
                }
                themeChanger.allWallpapers = tempWallpapers
                filterWallpapers(searchInput.text)
            }
        }
    }

    function filterWallpapers(query) {
        filteredModel.clear()
        const q = query.toLowerCase()
        for (let wp of themeChanger.allWallpapers) {
            if (wp.name.toLowerCase().includes(q)) filteredModel.append(wp)
        }
        wallList.currentIndex = -1
    }

    Process {
        id: themeRunner
        property string targetWallpaper: ""
        command: ["bash", "-c", "~/Personal_Scripts/pywal_global_update.sh \"" + targetWallpaper + "\""]
    }

    function applyWallpaper(path) {
        themeRunner.targetWallpaper = path
        themeRunner.running = false
        themeRunner.running = true
    }
}