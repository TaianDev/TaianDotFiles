// Archivo: modules/lockscreen/lock.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "."

ShellRoot {
    property string homeDir: ""

    Process {
        id: homeResolver
        command: ["sh", "-c", "echo -n \"$HOME\""]
        stdout: StdioCollector {
            onStreamFinished: root.homeDir = this.text.trim()
        }
        running: true
    }

    onHomeDirChanged: {
        if (homeDir !== "") {
            themeFileView.path = root.homeDir + "/.config/quickshell/Theme.qml"
            themeFileView.reload()
        }
    }

    FileView {
        id: themeFileView
        onLoaded: {
            var text = themeFileView.text()
            if (!text || text.length === 0) return

            var colors = {}
            var regex = /readonly property color (\w+):\s*"([#][0-9a-fA-F]{6,8})"/g
            var match
            while ((match = regex.exec(text)) !== null)
                colors[match[1]] = match[2]

            if (Object.keys(colors).length >= 10)
                Theme.applyFromParsed(colors)
        }
    }

    LockContext {
        id: lockContext
        onUnlocked: {
            lock.locked = false;
            Qt.quit(); 
        }
    }
    WlSessionLock {
        id: lock
        locked: true
        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }
}

