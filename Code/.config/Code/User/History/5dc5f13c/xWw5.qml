import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

Item {
    id: root

    property string iconsPath: Qt.resolvedUrl("../../assets/icons/")

    // ── API Bluetooth ─────────────────────────────────────────
    readonly property var  adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter?.enabled ?? false

    // Buscar el primer dispositivo conectado
    readonly property var connectedDevice: {
        if (!adapter) return null
        const devList = adapter.devices.values
        for (let i = 0; i < devList.length; i++) {
            if (devList[i].connected) return devList[i]
        }
        return null
    }

    readonly property string deviceName: connectedDevice?.name ?? ""

    // ── Propiedades Visuales ──────────────────────────────────
    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight
    
    // Efecto visual: Se atenúa si el Bluetooth está apagado
    opacity: enabled ? 1.0 : 0.4
    Behavior on opacity { NumberAnimation { duration: 200 } }

    RowLayout {
        id: row
        spacing: 5

        // Icono Dinámico
        SvgIcon {
            source: root.enabled
                ? root.iconsPath + "bluetooth.svg"
                : root.iconsPath + "no-bluetooth.svg"
            size: 13
        }

        // Texto Dinámico (Nombre del dispositivo o estado)
        ScrollingText {
            text: root.enabled
                ? (root.deviceName !== "" ? root.deviceName : "No device")
                : "BT Off"
            maxWidth: 60
            fontSize: 11
            color: (root.enabled && root.deviceName !== "")
                ? "#ffffff" : Qt.rgba(1,1,1,0.4)
        }
    }
}