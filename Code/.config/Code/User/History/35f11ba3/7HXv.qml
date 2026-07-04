import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as Net   // contiene NetworkDeviceType

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property real rxSpeed: 0
    property real txSpeed: 0

    function formatSpeed(bps) {
        if (bps < 1024)        return Math.round(bps) + "B/s"
        if (bps < 1048576)     return (bps / 1024).toFixed(1) + "K/s"
        return (bps / 1048576).toFixed(1) + "M/s"
    }

    // ── Dispositivo WiFi nativo ────────────────────────────────
    readonly property var wifiDevice: {
        for (var i = 0; i < Net.Networking.devices.count; i++) {
            var dev = Net.Networking.devices.get(i)
            if (dev.type === Net.NetworkDeviceType.Wifi)
                return dev
        }
        return null
    }

    readonly property bool enabled:   wifiDevice !== null
    readonly property bool connected: wifiDevice?.connected ?? false

    // ── Red conectada ──────────────────────────────────────────
    readonly property var activeNetwork: {
        if (!wifiDevice) return null
        for (var j = 0; j < wifiDevice.networks.count; j++) {
            var net = wifiDevice.networks.get(j)
            if (net.connected) return net
        }
        return null
    }

    readonly property string ssid:     activeNetwork?.ssid     ?? ""
    readonly property int    strength: activeNetwork?.strength ?? 0

    readonly property string icon: {
        if (!enabled)   return iconsPath + "no-wifi.svg"
        if (!connected) return iconsPath + "wifi-none.svg"
        if (strength >= 66) return iconsPath + "wifi-full.svg"
        if (strength >= 33) return iconsPath + "wifi-medium.svg"
        return iconsPath + "wifi-low.svg"
    }

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        id: row
        spacing: 5

        SvgIcon { source: root.icon; size: 13 }

        ScrollingText {
            text: root.connected ? root.ssid
                : (root.enabled ? "Sin red" : "WiFi Off")
            maxWidth: 60
            fontSize: 11
            color: root.connected ? "#ffffff" : Qt.rgba(1,1,1,0.4)
        }

        RowLayout {
            spacing: 4
            visible: root.connected

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