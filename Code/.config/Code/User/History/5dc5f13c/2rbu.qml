import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    function formatSpeed(bps) {
        if (bps < 1024)    return Math.round(bps) + "B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + "K/s"
        return (bps / 1048576).toFixed(1) + "M/s"
    }

    // ── API Bluetooth ─────────────────────────────────────────
    readonly property var    adapter:      Bluetooth.defaultAdapter
    readonly property bool   enabled:      adapter?.enabled ?? false

    // Buscar el primer dispositivo conectado
    readonly property var connectedDevice: {
        if (!adapter) return null
        const devList = adapter.devices.values
        for (let i = 0; i < devList.length; i++)
            if (devList[i].connected) return devList[i]
        return null
    }

    readonly property string deviceName: connectedDevice?.name ?? ""

    // ── Velocidades ──────────────────────────────────────────
    property real rxSpeed: 0
    property real txSpeed: 0
    property real _lastRx: 0
    property real _lastTx: 0

    Timer {
        interval: 2000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Leer estadísticas de bytes (rutas típicas; ajústalas si es necesario)
            try {
                var rxStr = File.read("/sys/class/bluetooth/hci0/statistics/rx_bytes").trim()
                var txStr = File.read("/sys/class/bluetooth/hci0/statistics/tx_bytes").trim()
                var rx = parseFloat(rxStr)
                var tx = parseFloat(txStr)
                if (!isNaN(rx) && !isNaN(tx)) {
                    if (root._lastRx > 0) {
                        root.rxSpeed = Math.max(0, (rx - root._lastRx) / 2)
                        root.txSpeed = Math.max(0, (tx - root._lastTx) / 2)
                    }
                    root._lastRx = rx
                    root._lastTx = tx
                }
            } catch (e) {
                // Si las rutas no existen, se mantiene en 0
            }
        }
    }

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        id: row
        spacing: 5

        SvgIcon {
            source: root.enabled
                ? root.iconsPath + "bluetooth.svg"
                : root.iconsPath + "no-bluetooth.svg"
            size: 13
        }

        ScrollingText {
            text: root.enabled
                ? (root.deviceName !== "" ? root.deviceName : "No device")
                : "BT Off"
            maxWidth: 60
            fontSize: 11
            color: (root.enabled && root.deviceName !== "")
                ? "#ffffff" : Qt.rgba(1,1,1,0.4)
        }

        RowLayout {
            spacing: 4
            visible: root.enabled && root.connectedDevice !== null

            RowLayout {
                spacing: 2
                SvgIcon { source: root.iconsPath + "receive.svg"; size: 10; tint: "#89dceb" }
                Text { text: root.formatSpeed(root.rxSpeed); color: "#89dceb"; font.pixelSize: 10 }
            }
            RowLayout {
                spacing: 2
                SvgIcon { source: root.iconsPath + "transmit.svg"; size: 10; tint: "#a6e3a1" }
                Text { text: root.formatSpeed(root.txSpeed); color: "#a6e3a1"; font.pixelSize: 10 }
            }
        }
    }
}