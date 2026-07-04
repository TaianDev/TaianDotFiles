import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: wallPopup
    color: "transparent"
    
    // 🌟 Diseño Vertical
    implicitWidth: 380
    implicitHeight: 700
    
    // Ajusta los anclajes según dónde quieras que flote (ej. debajo de la barra superior, a la izquierda)
    anchors {
        top: true
        left: true
        topMargin: 48
        leftMargin: 16
    }
    
    exclusiveZone: 0 
    WlrLayershell.namespace: "wallpaper_selector"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isOpened: false
    property color themeBg: "#1a1a1e" 
    property color themeAccent: "#89b4fa" // Un azul elegante (puedes cambiarlo a tu gusto)
    
    property var allWallpapers: []
    property string activeWallpaperPath: ""

    visible: isOpened

    onIsOpenedChanged: {
        if (isOpened) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
            wallScanner.running = true // Refresca la lista al abrir
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        // 🌟 Cuerpo Principal con diseño suavizado
        Rectangle {
            id: mainBody
            anchors.fill: parent
            radius: 16
            color: wallPopup.themeBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                // ─── CABECERA ───
                RowLayout {
                    Layout.fillWidth: true
                    
                    Text {
                        text: "🖼️ Wallpapers"
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
                    Layout.preferredHeight: 40
                    placeholderText: "Search wallpapers..."
                    color: "#ffffff"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                    font.pixelSize: 13
                    activeFocusOnPress: false 
                    
                    background: Rectangle {
                        radius: 8
                        color: Qt.rgba(0, 0, 0, 0.3)
                        border.width: 1
                        border.color: searchInput.activeFocus ? wallPopup.themeAccent : Qt.rgba(1, 1, 1, 0.1)
                    }

                    onTextChanged: filterWallpapers(text)
                    Keys.onEscapePressed: wallPopup.isOpened = false
                }

                // ─── CUADRÍCULA DE IMÁGENES ───
                GridView {
                    id: wallGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: ListModel { id: filteredModel }
                    clip: true
                    
                    // Configuramos 2 columnas perfectas
                    cellWidth: width / 2
                    cellHeight: cellWidth * 0.6 // Relación de aspecto panorámica
                    
                    ScrollBar.vertical: ScrollBar { 
                        policy: ScrollBar.AsNeeded
                        width: 4
                    }

                    delegate: Item {
                        width: wallGrid.cellWidth
                        height: wallGrid.cellHeight
                        
                        property bool isActive: model.path === wallPopup.activeWallpaperPath

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 8
                            color: "transparent"
                            clip: true
                            border.width: isActive ? 2 : (itemMa.containsMouse ? 1 : 0)
                            border.color: isActive ? wallPopup.themeAccent : Qt.rgba(1, 1, 1, 0.3)
                            
                            // Efecto hover sutil en la escala
                            scale: itemMa.containsMouse && !isActive ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            // Imagen de fondo
                            Image {
                                anchors.fill: parent
                                source: "file://" + model.path
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true // ¡CRÍTICO! Para que la barra no se congele al cargar 78+ imágenes
                                sourceSize: Qt.size(300, 200) // Renderiza a baja resolución para ahorrar RAM
                            }

                            // Gradiente oscuro inferior para que el texto sea legible
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 32
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
                                }
                            }

                            // Nombre del archivo
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
                            
                            // Etiqueta "Active"
                            Rectangle {
                                visible: isActive
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 44; height: 18
                                radius: 9
                                color: wallPopup.themeAccent
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Active"
                                    color: "#000000"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                            
                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    wallPopup.activeWallpaperPath = model.path
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

    // 1. Escáner de la carpeta de imágenes
    Process {
        id: wallScanner
        // Busca JPG, PNG, JPEG y WEBP en tu carpeta
        command: ["bash", "-c", "find ~/Imágenes/Fondos -maxdepth 1 -type f \\( -iname \\*.jpg -o -iname \\*.png -o -iname \\*.jpeg -o -iname \\*.webp \\) | sort"]
        
        stdout: StdioCollector {
            onStreamFinished: {
                wallPopup.allWallpapers = []
                const lines = this.text.trim().split('\n')
                for (let line of lines) {
                    if (!line) continue
                    let fileName = line.substring(line.lastIndexOf('/') + 1)
                    wallPopup.allWallpapers.push({ path: line, name: fileName })
                }
                filterWallpapers(searchInput.text)
            }
        }
    }
    
    Component.onCompleted: wallScanner.running = true

    function filterWallpapers(query) {
        filteredModel.clear()
        const q = query.toLowerCase()
        for (let wp of wallPopup.allWallpapers) {
            if (wp.name.toLowerCase().includes(q)) {
                filteredModel.append(wp)
            }
        }
    }

    // 2. Ejecutor del Script Pywal
    Process {
        id: themeRunner
        property string targetWallpaper: ""
        // Ejecuta tu script global pasándole la ruta absoluta como argumento 1
        command: ["bash", "-c", "~/Personal_Scripts/pywal_global_update.sh \"" + targetWallpaper + "\""]
    }

    function applyWallpaper(path) {
        themeRunner.targetWallpaper = path
        themeRunner.running = false
        themeRunner.running = true
        // Opcional: Cerrar el popup tras aplicar
        // wallPopup.isOpened = false 
    }
}