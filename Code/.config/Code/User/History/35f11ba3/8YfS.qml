import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")
    property real rxSpeed: 0
    property real txSpeed: 0

    function formatSpeed(bps) {
        if (bps < 1024)    return Math.round(bps) + "B/s"
        if (bps < 1048576) return (bps / 1024).toFixed(1) + "K/s"
        return (bps / 1048576).toFixed(1) + "M/s"
    }

    readonly property var wifiDevice: {
        const devs = Networking.devices.values
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi) return devs[i]
        return null
    }

    readonly property bool enabled:   wifiDevice !== null
    readonly property bool connected: wifiDevice?.connected ?? false

    // Network.name = SSID, Network.connected = si está activa
    // WifiNetwork.signalStrength = 0.0 a 1.0
    readonly property var activeNetwork: {
        if (!wifiDevice) return null
        const nets = wifiDevice.networks.values
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected) return nets[i]
        return null
    }

    readonly property string ssid:     activeNetwork?.name           ?? ""
    readonly property real   strength: activeNetwork?.signalStrength ?? 0.0

    readonly property string icon: {
        if (!enabled)   return iconsPath + "no-wifi.svg"
        if (!connected) return iconsPath + "wifi-none.svg"
        if (strength >= 0.66) return iconsPath + "wifi-full.svg"
        if (strength >= 0.33) return iconsPath + "wifi-medium.svg"
        return iconsPath + "wifi-low.svg"
    }

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }

RowLayout {
    spacing: 4
    visible: root.connected

    RowLayout {
        spacing: 2
        SvgIcon { source: root.iconsPath + "receive.svg"; size: 10; tint: "#89dceb" }
        Text {
            text: root.formatSpeed(root.rxSpeed)
            color: "#89dceb"
            font.pixelSize: 10
            width: 55                // ← fijo
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideNone    // opcional, evita "..."
        }
    }
    RowLayout {
        spacing: 2
        SvgIcon { source: root.iconsPath + "transmit.svg"; size: 10; tint: "#a6e3a1" }
        Text {
            text: root.formatSpeed(root.txSpeed)
            color: "#a6e3a1"
            font.pixelSize: 10
            width: 55
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideNone
        }
    }
}
}
