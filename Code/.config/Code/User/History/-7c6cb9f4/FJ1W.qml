import QtQuick
import Quickshell.Io

Item {
    id: service
    visible: false

    signal applied(string path)

    property string wallpaperPath: ""

    Process {
        id: swwwProc
        property string path: ""
        command: [
            "swww", "img", path,
            "--transition-type", "wave",
            "--transition-fps", "60",
            "--transition-duration", "2"
        ]
        onExited: matugenProc.running = true
    }

    Process {
        id: matugenProc
        property string path: ""
        command: ["matugen", "image", path, "--source-color-index", "0", "-t", "vibrant"]
        onExited: walProc.running = true
    }

    Process {
        id: walProc
        property string path: ""
        command: ["wal", "-qste", "-i", path]
        onExited: service.applied(service.wallpaperPath)
    }

    function apply(path) {
        wallpaperPath = path
        swwwProc.path = path
        matugenProc.path = path
        walProc.path = path
        swwwProc.running = false
        swwwProc.running = true
    }
}
