// WifiModule.qml — WiFi: icono señal, nombre de red, velocidades
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    // Velocidades calculadas externamente (desde NetworkPill)
    property real rxSpeed: 0
    property real txSpeed: 0

    function formatSpeed(bps) {
        if (bps < 1024)          return Math.round(bps) + "B/s"
        if (bps < 1024 * 1024)   return (bps / 1024).toFixed(1) + "K/s"
        return (bps / (1024 * 1024)).toFixed(1) + "M/s"
    }

    // ── API Quickshell.Networking ──────────────────────────────
    readonly property var wifiDevice: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i]
        return null
    }

    readonly property bool enabled:   wifiDevice !== null
    readonly property bool connected: wifiDevice?.connected ?? false
    readonly property int  strength:  wifiDevice?.activeAccessPoint?.strength ?? 0
    readonly property string ssid:    wifiDevice?.activeAccessPoint?.ssid ?? ""

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

        // Icono WiFi
        SvgIcon { source: root.icon; size: 13 }

        // Nombre de red (scroll si >5 chars)
        ScrollingText {
            text:     root.connected ? root.ssid : (root.enabled ? "Sin red" : "WiFi Off")
            maxWidth: 60
            fontSize: 11
            color:    root.connected ? "#ffffff" : Qt.rgba(1,1,1,1)
        }

        // Velocidades (solo si conectado)
        RowLayout {
            spacing: 4
            visible: root.connected

            RowLayout {
                spacing: 2
                SvgIcon {
                    source: root.iconsPath + "receive.svg"
                    size: 10; tint: "#89dceb"
                }
                Text {
                    text:  root.formatSpeed(root.rxSpeed)
                    color: "#89dceb"; font.pixelSize: 10
                }
            }

            RowLayout {
                spacing: 2
                SvgIcon {
                    source: root.iconsPath + "transmit.svg"
                    size: 10; tint: "#a6e3a1"
                }
                Text {
                    text:  root.formatSpeed(root.txSpeed)
                    color: "#a6e3a1"; font.pixelSize: 10
                }
            }
        }
    }
}
