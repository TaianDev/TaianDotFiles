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
    
    // Ancho total incluyendo las aletas cóncavas
    implicitWidth: 400 
    
    anchors {
        top: true
        bottom: true
        left: true
    }
    
    exclusiveZone: 0 
    WlrLayershell.namespace: "theme_changer"
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
            wallScanner.running = true 
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        // 🌟 FORMA VECTORIAL CÓNCAVA VERTICAL
        Shape {
            anchors.fill: parent
            antialiasing: true
            layer.enabled: true
            layer.samples: 8

            // 1. Relleno
            ShapePath {
                fillColor: themeChanger.themeBg
                strokeWidth: 0

                startX: 0; startY: 0
                // Techo superior
                PathLine { x: contentItem.width; y: 0 }
                // Aleta cóncava superior derecha (se hunde hacia la izquierda)
                PathQuad { x: contentItem.width - 20; y: 20; controlX: contentItem.width; controlY: 20 }
                // Pared derecha
                PathLine { x: contentItem.width - 20; y: contentItem.height - 20 }
                // Aleta cóncava inferior derecha (sale hacia la derecha)
                PathQuad { x: contentItem.width; y: contentItem.height; controlX: contentItem.width; controlY: contentItem.height - 20 }
                // Suelo inferior
                PathLine { x: 0; y: contentItem.height }
                // Cierre
                PathLine { x: 0; y: 0 }
            }

            // 2. Borde exterior
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(1, 1, 1, 0.1)
                strokeWidth: 1

                startX: 0; startY: 0
                PathLine { x: contentItem.width; y: 0 }
                PathQuad { x: contentItem.width - 20; y: 20; controlX: contentItem.width; controlY: 20 }
                PathLine { x: contentItem.width - 20; y: contentItem.height - 20 }
                PathQuad { x: contentItem.width; y: contentItem.height; controlX: contentItem.width; controlY: contentItem.height - 20 }
                PathLine { x: 0; y: contentItem.height }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            // El margen derecho es de 40 para no pisar la aleta cóncava
            anchors.margins: 20
            anchors.rightMargin: 40 
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "🎨 Themes & Wallpapers"
                    color: "#ffffff"
                    font.pixelSize: 16
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
                        text: filteredModel.count + " items"
                        color: Qt.rgba(1, 1, 1, 0.7)
                        font.pixelSize: 11
                    }
                }
            }

            TextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                placeholderText: "🔍 Buscar fondos..."
                color: "#ffffff"
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: 14
                activeFocusOnPress: false 
                
                background: Rectangle {
                    radius: 12
                    color: Qt.rgba(0, 0, 0, 0.5)
                    border.width: 1
                    border.color: searchInput.activeFocus ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                }

                onTextChanged: filterWallpapers(text)
                Keys.onEscapePressed: themeChanger.isOpened = false
            }

            GridView {
                id: wallGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: ListModel { id: filteredModel }
                clip: true
                
                cellWidth: width / 2
                cellHeight: cellWidth * 0.6 
                
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

                delegate: Item {
                    width: wallGrid.cellWidth
                    height: wallGrid.cellHeight
                    
                    property bool isActive: model.path === themeChanger.activeWallpaperPath

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 10
                        color: "transparent"
                        clip: true
                        border.width: isActive ? 2 : (itemMa.containsMouse ? 1 : 0)
                        border.color: isActive ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.3)
                        
                        scale: itemMa.containsMouse && !isActive ? 1.03 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Image {
                            anchors.fill: parent
                            source: "file://" + model.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(200, 120) 
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 32
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.9) }
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
                            width: 40; height: 16
                            radius: 8
                            color: themeChanger.themeAccent
                            Text { anchors.centerIn: parent; text: "Active"; color: "#000000"; font.pixelSize: 9; font.bold: true }
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
        }
    }

    Process {
        id: wallScanner
        command: ["bash", "-c", "find ~/Imágenes/Fondos -maxdepth 1 -type f \\( -iname \\*.jpg -o -iname \\*.png -o -iname \\*.jpeg -o -iname \\*.webp \\) | sort"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                themeChanger.allWallpapers = []
                const lines = this.text.trim().split('\n')
                for (let line of lines) {
                    if (!line) continue
                    let fileName = line.substring(line.lastIndexOf('/') + 1)
                    themeChanger.allWallpapers.push({ path: line, name: fileName })
                }
                filterWallpapers(searchInput.text)
            }
        }
    }
    
    Component.onCompleted: wallScanner.running = true

    function filterWallpapers(query) {
        filteredModel.clear()
        const q = query.toLowerCase()
        for (let wp of themeChanger.allWallpapers) {
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
    }
}