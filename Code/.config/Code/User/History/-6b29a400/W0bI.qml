import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: themeChanger
    color: "transparent"
    
    // Anclado a la parte inferior, flotando ligeramente
    anchors {
        bottom: true
        left: true
        right: true
        bottomMargin: 20
        leftMargin: 40
        rightMargin: 40
    }
    
    implicitHeight: 380
    
    exclusiveZone: 0 
    WlrLayershell.namespace: "theme_changer"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property bool isOpened: false
    
    // Colores base (Cámbialos por Theme.surface y Theme.onSurface si ya activaste Matugen)
    property color themeBg: "#181825" 
    property color themeAccent: "#cba6f7"
    
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

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(themeBg.r, themeBg.g, themeBg.b, 0.95)
        radius: 16
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
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
                
                // Ocultar barra de desplazamiento para un look más limpio
                ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                delegate: Item {
                    // Tarjetas verticales (estilo portrait)
                    width: 160
                    height: wallList.height
                    
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

                        // Miniatura recortada en vertical
                        Image {
                            anchors.fill: parent
                            source: "file://" + model.path
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Qt.size(200, 400) 
                        }

                        // Gradiente para el texto
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width; height: 40
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.9) }
                            }
                        }

                        // Nombre del archivo
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

            // ─── BARRA DE BÚSQUEDA CENTRADA ───
            TextField {
                id: searchInput
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 400
                Layout.preferredHeight: 44
                
                placeholderText: "🔍 Search wallpapers..."
                color: "#ffffff"
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.5)
                font.pixelSize: 14
                activeFocusOnPress: false 
                
                background: Rectangle {
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.4)
                    border.width: 1
                    border.color: searchInput.activeFocus ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                }

                onTextChanged: filterWallpapers(text)
                Keys.onEscapePressed: themeChanger.isOpened = false
                
                // Navegación con teclado
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

    // ─── BACKEND SCANNER ───
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

    function filterWallpapers(query) {
        filteredModel.clear()
        const q = query.toLowerCase()
        for (let wp of themeChanger.allWallpapers) {
            if (wp.name.toLowerCase().includes(q)) filteredModel.append(wp)
        }
        wallList.currentIndex = -1
    }

    // ─── EJECUCIÓN DE TU SCRIPT ───
    Process {
        id: themeRunner
        property string targetWallpaper: ""
        command: ["bash", "-c", "~/Personal_Scripts/pywal_global_update.sh \"" + targetWallpaper + "\""]
    }

    function applyWallpaper(path) {
        themeRunner.targetWallpaper = path
        themeRunner.running = false
        themeRunner.running = true
        
        // No necesitas cerrar el popup manualmente, ya que tu script bash
        // se encarga de matar Quickshell y reiniciarlo (killall quickshell &).
    }
}