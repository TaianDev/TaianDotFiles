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

    // ─── ESTADO DE RUTAS ───
    // homeDir se resuelve vía shell (misma vía que usa find, así ambos coinciden siempre)
    property string homeDir: ""
    property string basePath: ""
    property string currentPath: ""

    property var allWallpapers: []
    property bool folderBrowserOpen: false

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
            folderBrowserOpen = false
            searchInput.text = ""
            wallList.currentIndex = -1

            if (themeChanger.homeDir === "") {
                // Todavía no se resolvió $HOME: se resolverá y disparará el escaneo solo.
                homeResolver.running = true
            } else {
                // Siempre volvemos a la carpeta base al reabrir el panel.
                currentPath = basePath
                scanWallpapers(currentPath)
            }
            searchInput.forceActiveFocus()
        }
    }

    // ─── RESOLUCIÓN DE $HOME (una sola vez al iniciar) ───
    Process {
        id: homeResolver
        command: ["bash", "-c", "echo -n \"$HOME\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                themeChanger.homeDir = this.text.trim()
                themeChanger.basePath = themeChanger.homeDir + "/Imágenes/Fondos"
                themeChanger.currentPath = themeChanger.basePath
                if (themeChanger.isOpened) {
                    scanWallpapers(themeChanger.currentPath)
                }
            }
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        // 🌟 CUERPO PRINCIPAL UNIFICADO (Misma lógica que AppLauncher)
        Item {
            id: mainBody
            width: 900
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
                spacing: 16

                // ─── RUTA ACTUAL (breadcrumb) ───
                Text {
                    Layout.fillWidth: true
                    visible: themeChanger.currentPath !== "" && themeChanger.currentPath !== themeChanger.basePath
                    text: "📁 " + themeChanger.currentPath.replace(themeChanger.basePath, "Fondos")
                    color: Qt.rgba(1, 1, 1, 0.55)
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                }

                // ─── CARRUSEL HORIZONTAL ───
                ListView {
                    id: wallList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    spacing: 16
                    model: ListModel { id: filteredModel }
                    clip: true
                    focus: false
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    delegate: Item {
                        width: 180
                        height: ListView.view.height

                        property bool isActive: model.path === themeChanger.activeWallpaperPath
                        property bool isSelected: index === wallList.currentIndex

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            clip: true
                            border.width: isActive ? 2 : (isSelected || itemMa.containsMouse ? 1 : 0)
                            border.color: isActive ? themeChanger.themeAccent
                                          : (isSelected ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.3))

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
                                    wallList.currentIndex = index
                                    themeChanger.activeWallpaperPath = model.path
                                    applyWallpaper(model.path)
                                }
                            }
                        }
                    }
                }

                // ─── BARRA INFERIOR: carpeta · búsqueda · apply ───
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Botón de carpeta: abre el navegador de directorios
                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 12
                        color: Qt.rgba(0, 0, 0, 0.5)
                        border.width: 1
                        border.color: folderBrowserOpen ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: "📁"
                            font.pixelSize: 18
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                themeChanger.folderBrowserOpen = !themeChanger.folderBrowserOpen
                                if (themeChanger.folderBrowserOpen) {
                                    scanDirectories(themeChanger.currentPath)
                                }
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
                            border.color: searchInput.activeFocus ? themeChanger.themeAccent : Qt.rgba(1, 1, 1, 0.15)
                        }

                        onTextChanged: filterWallpapers(text)
                        Keys.onEscapePressed: {
                            if (themeChanger.folderBrowserOpen) {
                                themeChanger.folderBrowserOpen = false
                            } else {
                                themeChanger.isOpened = false
                            }
                        }

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
                        Keys.onReturnPressed: applySelected()
                        Keys.onEnterPressed: applySelected()
                    }

                    // ─── BOTÓN APPLY ───
                    Rectangle {
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 44
                        radius: 12
                        color: themeChanger.themeAccent

                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            font.pixelSize: 14
                            font.bold: true
                            color: "#1a1a1e"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: applySelected()
                        }
                    }
                }
            }

            // ─── OVERLAY: NAVEGADOR DE DIRECTORIOS ───
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Qt.rgba(0, 0, 0, 0.75)
                visible: themeChanger.folderBrowserOpen

                MouseArea {
                    // Clic fuera del panel de directorios lo cierra
                    anchors.fill: parent
                    onClicked: themeChanger.folderBrowserOpen = false
                }

                Rectangle {
                    width: 460
                    height: 360
                    anchors.centerIn: parent
                    radius: 16
                    color: "#1a1a1e"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    MouseArea {
                        // Evita que el clic dentro del panel lo cierre
                        anchors.fill: parent
                        onClicked: {}
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: "Navegar carpetas"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            Text {
                                text: "✕"
                                color: Qt.rgba(1, 1, 1, 0.6)
                                font.pixelSize: 14
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: themeChanger.folderBrowserOpen = false
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: themeChanger.currentPath.replace(themeChanger.basePath, "Fondos")
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.pixelSize: 10.5
                            elide: Text.ElideMiddle
                        }

                        ListView {
                            id: dirList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: ListModel { id: dirModel }
                            spacing: 4

                            delegate: Rectangle {
                                width: dirList.width
                                height: 38
                                radius: 8
                                color: dirMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    Text {
                                        text: model.isUp ? "⬆" : "📁"
                                        font.pixelSize: 14
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: model.name
                                        color: "#ffffff"
                                        font.pixelSize: 12.5
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: dirMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: navigateToDirectory(model.path)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 10
                            color: themeChanger.themeAccent

                            Text {
                                anchors.centerIn: parent
                                text: "Usar esta carpeta"
                                font.pixelSize: 12.5
                                font.bold: true
                                color: "#1a1a1e"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: themeChanger.folderBrowserOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── BACKEND: ESCANEO DE FONDOS (imágenes en currentPath) ───
    Process {
        id: wallScanner
        stdout: StdioCollector {
            onStreamFinished: {
                let tempWallpapers = []
                const trimmed = this.text.trim()
                if (trimmed.length > 0) {
                    const lines = trimmed.split('\n')
                    for (let line of lines) {
                        if (!line) continue
                        let fileName = line.substring(line.lastIndexOf('/') + 1)
                        tempWallpapers.push({ path: line, name: fileName })
                    }
                }
                themeChanger.allWallpapers = tempWallpapers
                filterWallpapers(searchInput.text)
            }
        }
    }

    function scanWallpapers(path) {
        if (!path) return
        wallScanner.running = false
        wallScanner.command = ["bash", "-c",
            "find \"" + path + "\" -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) " +
            "2>/dev/null | sort"]
        wallScanner.running = true
    }

    // ─── BACKEND: ESCANEO DE SUBDIRECTORIOS (para el navegador de carpetas) ───
    Process {
        id: dirScanner
        property string scannedPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                dirModel.clear()
                if (dirScanner.scannedPath !== themeChanger.basePath) {
                    let parentPath = dirScanner.scannedPath.substring(0, dirScanner.scannedPath.lastIndexOf('/'))
                    dirModel.append({ path: parentPath, name: ".. (carpeta superior)", isUp: true })
                }
                const trimmed = this.text.trim()
                if (trimmed.length > 0) {
                    const lines = trimmed.split('\n')
                    for (let line of lines) {
                        if (!line) continue
                        let dirName = line.substring(line.lastIndexOf('/') + 1)
                        dirModel.append({ path: line, name: dirName, isUp: false })
                    }
                }
            }
        }
    }

    function scanDirectories(path) {
        if (!path) return
        dirScanner.scannedPath = path
        dirScanner.running = false
        dirScanner.command = ["bash", "-c",
            "find \"" + path + "\" -mindepth 1 -maxdepth 1 -type d -not -name '.*' 2>/dev/null | sort"]
        dirScanner.running = true
    }

    function navigateToDirectory(path) {
        themeChanger.currentPath = path
        scanWallpapers(path)
        scanDirectories(path)
    }

    function filterWallpapers(query) {
        filteredModel.clear()
        const q = (query || "").toLowerCase()
        for (let wp of themeChanger.allWallpapers) {
            if (wp.name.toLowerCase().includes(q)) filteredModel.append(wp)
        }
        wallList.currentIndex = -1
    }

    function applySelected() {
        let targetIdx = wallList.currentIndex >= 0 ? wallList.currentIndex : 0
        if (filteredModel.count > 0) {
            let item = filteredModel.get(targetIdx)
            themeChanger.activeWallpaperPath = item.path
            applyWallpaper(item.path)
        }
    }

    property string activeWallpaperPath: ""

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
