import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: wallLauncher
    color: "transparent"
    
    // Ancho del panel
    implicitWidth: 400
    
    // Se ancla a todo el borde izquierdo
    anchors {
        top: true
        bottom: true
        left: true
    }
    
    exclusiveZone: 0 
    WlrLayershell.namespace: "wallpaper_launcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isOpened: false
    property color themeBg: "#1a1a1e" 
    property color themeAccent: "#89b4fa"
    property var allWallpapers: []
    property string activeWallpaperPath: ""

    visible: isOpened

    onIsOpenedChanged: {
        if (isOpened) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
            wallScanner.running = true // Refrescar lista al abrir
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        Item {
            id: mainBody
            width: parent.width
            height: parent.height

            // 🌟 FORMA VECTORIAL: Anclada a la izquierda, con esquinas redondeadas a la derecha
            Shape {
                anchors.fill: parent
                // Expandimos arriba y abajo para los posibles cortes si no ocupa toda la pantalla,
                // aunque estando anclado top y bottom, suele llenar la vertical completa.
                antialiasing: true
                layer.enabled: true
                layer.samples: 8

                // PATH DE RELLENO
                ShapePath {
                    fillColor: wallLauncher.themeBg
                    strokeWidth: 0

                    startX: 0; startY: 0
                    PathLine { x: mainBody.width - 20; y: 0 }
                    PathArc { x: mainBody.width; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: mainBody.width; y: mainBody.height - 20 }
                    PathArc { x: mainBody.width - 20; y: mainBody.height; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 0; y: mainBody.height }
                    PathLine { x: 0; y: 0 }
                }

                // PATH DE BORDE (Línea derecha y curvas)
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.rgba(1, 1, 1, 0.1)
                    strokeWidth: 1

                    startX: 0; startY: 0
                    PathLine { x: mainBody.width - 20; y: 0 }
                    PathArc { x: mainBody.width; y: 20; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: mainBody.width; y: mainBody.height - 20 }
                    PathArc { x: mainBody.width - 20; y: mainBody.height; radiusX: 20; radiusY: 20; useLargeArc: false; direction: PathArc.Clockwise }
                    PathLine { x: 0; y: mainBody.height }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // ─── CABECERA ───
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "🖼️ Wallpapers"
                        color: "#ffffff"
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    Rectangle {
                        color: Qt.rgba(1, 1, 1, 0.1)
                        radius: 12
                        implicitWidth: countText.width + 16
                        implicitHeight: 24
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: filteredModel.count + " images"
                            color: Qt.rgba(1, 1, 1, 0.7)
                            font.pixelSize: 11
                        }
                    }
                }

                // ─── BARRA DE BÚSQUEDA ───
                TextField {
                    id: searchInput
                    Layout.fillWidth: true
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
                        border.color: searchInput.activeFocus ? wallLauncher.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                    }

                    onTextChanged: filterWallpapers(text)
                    Keys.onEscapePressed: wallLauncher.isOpened = false
                }

                // ─── LISTA/GRID DE FONDOS ───
                GridView {
                    id: wallGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ListModel { id: filteredModel }
                    clip: true
                    
                    // 2 columnas dentro del ancho del panel
                    cellWidth: width / 2
                    cellHeight: cellWidth * 0.6 
                    
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                    delegate: Item {
                        width: wallGrid.cellWidth
                        height: wallGrid.cellHeight
                        
                        property bool isActive: model.path === wallLauncher.activeWallpaperPath

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 12
                            color: "transparent"
                            clip: true
                            border.width: isActive ? 2 : (itemMa.containsMouse ? 1 : 0)
                            border.color: isActive ? wallLauncher.themeAccent : Qt.rgba(1, 1, 1, 0.3)
                            
                            scale: itemMa.containsMouse && !isActive ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Image {
                                anchors.fill: parent
                                source: "file://" + model.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize: Qt.size(200, 120) // Miniatura optimizada
                            }

                            // Sombra para el texto
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 28
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
                                }
                            }

                            Text {
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottomMargin: 6
                                width: parent.width - 12
                                text: model.name
                                color: "#ffffff"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            Rectangle {
                                visible: isActive
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 44; height: 18
                                radius: 9
                                color: wallLauncher.themeAccent
                                Text { anchors.centerIn: parent; text: "Active"; color: "#000000"; font.pixelSize: 9; font.bold: true }
                            }
                            
                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wallLauncher.activeWallpaperPath = model.path
                                    applyWallpaper(model.path)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── LÓGICA DEL BACKEND ───

    Process {
        id: wallScanner
        command: ["bash", "-c", "find ~/Imágenes/Fondos -maxdepth 1 -type f \\( -iname \\*.jpg -o -iname \\*.png -o -iname \\*.jpeg -o -iname \\*.webp \\) | sort"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                wallLauncher.allWallpapers = []
                const lines = this.text.trim().split('\n')
                for (let line of lines) {
                    if (!line) continue
                    let fileName = line.substring(line.lastIndexOf('/') + 1)
                    wallLauncher.allWallpapers.push({ path: line, name: fileName })
                }
                filterWallpapers(searchInput.text)
            }
        }
    }
    
    Component.onCompleted: wallScanner.running = true

    function filterWallpapers(query) {
        filteredModel.clear()
        const q = query.toLowerCase()
        for (let wp of wallLauncher.allWallpapers) {
            if (wp.name.toLowerCase().includes(q)) filteredModel.append(wp)
        }
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
        // Si quieres que el launcher se cierre al elegir un fondo, descomenta la siguiente línea:
        // wallLauncher.isOpened = false 
    }
}