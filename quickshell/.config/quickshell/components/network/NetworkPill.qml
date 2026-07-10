// NetworkPill.qml — cápsula WiFi + Bluetooth
// Uso: NetworkPill { anchors... }
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../core"
import "popup"

Rectangle {
    id: root
    height: 28
    width:  contentRow.implicitWidth + 24
    radius: height / 2
    color: Theme.barPillBackgroundColor()
    border.width: Theme.barPillBorderWidth
    border.color: Theme.barPillBorderColor()

    property var hostWindow: null

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    // ── Lectura de velocidades WiFi desde /proc/net/dev ────────
    property string netInterface: ""
    property real   rxSpeed: 0
    property real   txSpeed: 0
    property real  _lastRx:  0
    property real  _lastTx:  0

    FileView {
        id: netFile
        path: "/proc/net/dev"
        blockLoading: true
        watchChanges: false
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netFile.reload()
            const lines = netFile.text().split('\n')

            // Auto-detectar interfaz WiFi (empieza por 'w')
            if (root.netInterface === "") {
                for (let i = 2; i < lines.length; i++) {
                    const iface = lines[i].trim().split(':')[0].trim()
                    if (iface.startsWith('w')) { root.netInterface = iface; break }
                }
            }
            if (root.netInterface === "") return

            for (let i = 2; i < lines.length; i++) {
                const parts = lines[i].trim().split(/\s+/)
                if (parts[0] === root.netInterface + ":") {
                    const rx = parseFloat(parts[1])
                    const tx = parseFloat(parts[9])
                    if (root._lastRx > 0) {
                        root.rxSpeed = Math.max(0, (rx - root._lastRx) / 2)
                        root.txSpeed = Math.max(0, (tx - root._lastTx) / 2)
                    }
                    root._lastRx = rx; root._lastTx = tx
                    break
                }
            }
        }
    }

    // ── Layout ─────────────────────────────────────────────────
    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 10

        WifiModule {
            iconsPath: root.iconsPath
            rxSpeed:   root.rxSpeed
            txSpeed:   root.txSpeed
        }

        // Separador
        Rectangle {
            width: 1; height: 14
            color: Theme.alpha(Theme.outline, 0.4)
        }

        BluetoothModule {
            iconsPath: root.iconsPath
        }
    }

    // ── Interacción: Abrir Centro de Control (Solo Clic Derecho) ──
    function togglePopup() {
        netPopup.toggle()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    NetworkPopup {
        id: netPopup
        hostWindow: root.hostWindow
        anchorItem: root
    }
}
