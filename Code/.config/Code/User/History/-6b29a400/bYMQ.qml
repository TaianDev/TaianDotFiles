import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: themeChanger
    color: "transparent"

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
    property string homeDir: ""
    property string basePath: ""
    property string currentPath: ""
    property string activeWallpaperPath: ""
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
                homeResolver.running = true
            } else {
                currentPath = basePath
            }
            searchInput.forceActiveFocus()
        }
    }

    onCurrentPathChanged: {
        wallList.currentIndex = -1
    }

    // ─── RESOLUCIÓN DE $HOME ───
    Process {
        id: homeResolver
        command: ["bash", "-c", "echo -n \"$HOME\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                themeChanger.homeDir = this.text.trim()
                themeChanger.basePath = themeChanger.homeDir + "/Imágenes/Fondos"
                console.log("[theme_panel] basePath:", themeChanger.basePath)
                if (themeChanger.isOpened) {
                    themeChanger.currentPath = themeChanger.basePath
                }
            }
        }
    }

    // ─── MODELO NATIVO DE ARCHIVOS ───
    FolderListModel {
        id: wallpaperFolderModel
        folder: themeChanger.currentPath !== "" ? "file://" + themeChanger.currentPath : ""
        showDirs: false
        showFiles: true
        showDotAndDotDot: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                if (themeChanger.isOpened && wallList.currentIndex === -1 && count > 0) {
                    wallList.currentIndex = 0
                }
            }
        }
    }

    FolderListModel {
        id: dirFolderModel
        folder: themeChanger.currentPath !== "" ? "file://" + themeChanger.currentPath : ""
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    function updateSearchFilter(query) {
        const exts = ["jpg", "jpeg", "png", "webp", "bmp"]
        const q = (query && query.length > 0) ? ("*" + query + "*") : "*"
        let filters = []
        for (let e of exts) filters.push(q + "." + e)
        wallpaperFolderModel.nameFilters = filters
        wallList.currentIndex = -1
    }

    function parentOf(path) {
        let idx = path.lastIndexOf('/')
        return idx > 0 ? path.substring(0, idx) : path
    }

    function navigateToDirectory(path) {
        themeChanger.currentPath = path
    }

    // 🌟 Navegación simplificada (dejamos que QML maneje el desplazamiento visual)
    function moveSelection(delta) {
        if (wallpaperFolderModel.count === 0) return
        let newIndex = wallList.currentIndex + delta
        if (newIndex < 0) newIndex = 0
        if (newIndex > wallpaperFolderModel.count - 1) newIndex = wallpaperFolderModel.count - 1
        wallList.currentIndex = newIndex
    }

    function applySelected() {
        if (wallList.currentIndex < 0 && wallpaperFolderModel.count > 0) {
            wallList.currentIndex = 0
        }
        if (wallList.currentItem) {
            themeChanger.activeWallpaperPath = wallList.currentItem.myPath
            applyWallpaper(wallList.currentItem.myPath)
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent

        Item {
            id: mainBody
            width: 900
            height: parent.height
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter

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
                    model: wallpaperFolderModel
                    clip: true
                    focus: false
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }

                    // 🌟 Animación de desplazamiento nativa integrada en el ListView
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 250
                    highlightMoveVelocity: -1

                    delegate: Item {
                        id: wallDelegate
                        width: 180
                        height: ListView.view.height

                        property string myPath: filePath
                        property string myName: fileName
                        property bool isActive: myPath === themeChanger.activeWallpaperPath
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
                                source: "file://" + wallDelegate.myPath
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
                                text: wallDelegate.myName
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
                                    themeChanger.activeWallpaperPath = wallDelegate.myPath
                                    applyWallpaper(wallDelegate.myPath)
                                    searchInput.forceActiveFocus() // Devuelve el foco a la barra de búsqueda
                                }
                            }
                        }
                    }
                }

                // ─── BARRA INFERIOR ───
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

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
                            onClicked: themeChanger.folderBrowserOpen = !themeChanger.folderBrowserOpen
                        }
                    }

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

                        onTextChanged: updateSearchFilter(text)
                        
                        Keys.onEscapePressed: {
                            if (themeChanger.folderBrowserOpen) {
                                themeChanger.folderBrowserOpen = false
                            } else {
                                themeChanger.isOpened = false
                            }
                        }

                        // 🌟 Teclas Izquierda/Derecha liberadas para editar texto libremente
                        // Usamos Arriba (anterior) y Abajo (siguiente) para navegar la lista
                        Keys.onUpPressed: moveSelection(-1)
                        Keys.onDownPressed: moveSelection(1)
                        Keys.onReturnPressed: applySelected()
                        Keys.onEnterPressed: applySelected()
                    }

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
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }

                        ListView {
                            id: dirList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: dirFolderModel
                            spacing: 4

                            header: Rectangle {
                                width: dirList.width
                                height: themeChanger.currentPath !== themeChanger.basePath ? 38 : 0
                                visible: themeChanger.currentPath !== themeChanger.basePath
                                radius: 8
                                color: upMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8
                                    Text { text: "⬆"; font.pixelSize: 14 }
                                    Text {
                                        Layout.fillWidth: true
                                        text: ".. (carpeta superior)"
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                    }
                                }

                                MouseArea {
                                    id: upMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: navigateToDirectory(parentOf(themeChanger.currentPath))
                                }
                            }

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
                                    Text { text: "📁"; font.pixelSize: 14 }
                                    Text {
                                        Layout.fillWidth: true
                                        text: fileName
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: dirMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: navigateToDirectory(filePath)
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
                                font.pixelSize: 12
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

    // ─── APLICAR FONDO ───
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