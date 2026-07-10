import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import "../core"
import "../services"

Rectangle {
    id: capsule
    height: 28
    implicitWidth: wsContainer.implicitWidth + 24
    radius: height / 2
    color: Theme.barPillBackgroundColor()
    border.width: Theme.barPillBorderWidth
    border.color: Theme.barPillBorderColor()

    property string outputName: ""
    property string primaryMonitorName: "HDMI-A-1"
    property var targetWorkspaces: outputName === primaryMonitorName
        ? [1, 2, 3, 4, 5]
        : [6, 7, 8, 9, 10]

    readonly property int pillHeight: 22
    readonly property int pillVPad: (height - pillHeight) / 2

    Item {
        id: wsContainer
        anchors.centerIn: parent
        implicitWidth: wsRow.implicitWidth
        implicitHeight: capsule.pillHeight

        property Item activePill: null
        property bool bubbleReady: false

        property real blobCx: 0
        property real blobCy: capsule.pillHeight * 0.5
        property real blobW: 14
        property real blobH: capsule.pillHeight
        property string blobPath: ""

        function roundedRectPath(x, y, w, h, r) {
            if (w <= 0 || h <= 0)
                return ""
            r = Math.min(r, w * 0.5, h * 0.5)
            return "M " + (x + r) + " " + y
                + " H " + (x + w - r)
                + " Q " + (x + w) + " " + y + " " + (x + w) + " " + (y + r)
                + " V " + (y + h - r)
                + " Q " + (x + w) + " " + (y + h) + " " + (x + w - r) + " " + (y + h)
                + " H " + (x + r)
                + " Q " + x + " " + (y + h) + " " + x + " " + (y + h - r)
                + " V " + (y + r)
                + " Q " + x + " " + y + " " + (x + r) + " " + y
                + " Z"
        }

        function smoothClosedPath(points) {
            const n = points.length
            if (n < 3)
                return ""

            let d = "M " + points[0].x.toFixed(1) + " " + points[0].y.toFixed(1)
            for (let i = 0; i < n; i++) {
                const p0 = points[(i - 1 + n) % n]
                const p1 = points[i]
                const p2 = points[(i + 1) % n]
                const p3 = points[(i + 2) % n]
                const cp1x = p1.x + (p2.x - p0.x) / 6
                const cp1y = p1.y + (p2.y - p0.y) / 6
                const cp2x = p2.x - (p3.x - p1.x) / 6
                const cp2y = p2.y - (p3.y - p1.y) / 6
                d += " C " + cp1x.toFixed(1) + " " + cp1y.toFixed(1)
                    + ", " + cp2x.toFixed(1) + " " + cp2y.toFixed(1)
                    + ", " + p2.x.toFixed(1) + " " + p2.y.toFixed(1)
            }
            return d + " Z"
        }

        function irregularBlobPath(cx, cy, w, h, flowT) {
            const stretch = Math.sin(flowT * Math.PI)
            const wobbleAmp = stretch * (0.34 + 0.1 * Math.sin(flowT * 19.7))
            const phase = flowT * Math.PI * 9.5
            const skew = stretch * 0.22 * Math.sin(flowT * Math.PI * 4.1)

            const rx = w * 0.5
            const ry = Math.max(h * 0.5, 2)
            const segments = 16
            const points = []

            for (let i = 0; i < segments; i++) {
                const angle = (i / segments) * Math.PI * 2 - Math.PI * 0.5
                const bump = 1
                    + wobbleAmp * Math.sin(angle * 3 + phase)
                    + wobbleAmp * 0.62 * Math.sin(angle * 5 - phase * 1.55)
                    + wobbleAmp * 0.38 * Math.cos(angle * 2 + phase * 0.6)
                    + wobbleAmp * 0.28 * Math.sin(angle * 7 + phase * 2.3)
                const px = cx + Math.cos(angle) * rx * bump + skew * ry * Math.sin(angle)
                const py = cy + Math.sin(angle) * ry * bump
                points.push({ x: px, y: py })
            }

            return smoothClosedPath(points)
        }

        function flowGeometry(t) {
            const stretch = Math.sin(t * Math.PI)
            const eased = 0.5 - 0.5 * Math.cos(Math.PI * t)

            const toCx = liquidFlow.toX + liquidFlow.toW * 0.5
            const centerX = liquidFlow.fromCx + (toCx - liquidFlow.fromCx) * eased
            const bridge = Math.abs(toCx - liquidFlow.fromCx)

            const w = liquidFlow.fromW + (liquidFlow.toW - liquidFlow.fromW) * eased
                + stretch * (bridge + liquidFlow.fromW * 0.16 + liquidFlow.toW * 0.16)
            let h = liquidFlow.fromH + (liquidFlow.toH - liquidFlow.fromH) * eased
                - stretch * capsule.pillHeight * 0.46
            h = Math.max(h, 3)

            const x = centerX - w * 0.5
            const y = (capsule.pillHeight - h) * 0.5
            const r = Math.min(h * 0.5, w * 0.5)

            return { cx: centerX, cy: capsule.pillHeight * 0.5, w: w, h: h, x: x, y: y, r: r }
        }

        function setCleanBlobPath(geo) {
            blobPath = roundedRectPath(geo.x, geo.y, geo.w, geo.h, geo.r)
        }

        function snapBubbleToActive() {
            if (!activePill)
                return

            liquidAnim.stop()
            blobCx = activePill.x + activePill.width * 0.5
            blobCy = capsule.pillHeight * 0.5
            blobW = activePill.width
            blobH = capsule.pillHeight
            blobPath = roundedRectPath(
                activePill.x, 0, activePill.width, capsule.pillHeight, capsule.pillHeight * 0.5)
            liquidFlow.t = 1
        }

        function startLiquidFlow() {
            if (!activePill)
                return

            liquidFlow.fromCx = blobCx
            liquidFlow.fromW = blobW
            liquidFlow.fromH = blobH
            liquidFlow.toX = activePill.x
            liquidFlow.toW = activePill.width
            liquidFlow.toH = capsule.pillHeight
            liquidFlow.t = 0
            liquidAnim.stop()
            liquidAnim.start()
        }

        function updateBubbleFromFlow() {
            const t = liquidFlow.t
            if (t >= 1) {
                snapBubbleToActive()
                return
            }

            const geo = flowGeometry(t)
            blobCx = geo.cx
            blobCy = geo.cy
            blobW = geo.w
            blobH = geo.h

            // Deformación irregular solo en el tramo central del desplazamiento
            const irregularStart = 0.07
            const irregularEnd = 0.80

            if (t < irregularStart || t > irregularEnd) {
                setCleanBlobPath(geo)
                return
            }

            const innerT = (t - irregularStart) / (irregularEnd - irregularStart)
            blobPath = irregularBlobPath(blobCx, blobCy, blobW, blobH, innerT)
        }

        QtObject {
            id: liquidFlow
            property real t: 1
            property real fromCx: 7
            property real fromW: 14
            property real fromH: capsule.pillHeight
            property real toX: 0
            property real toW: 14
            property real toH: capsule.pillHeight
        }

        NumberAnimation {
            id: liquidAnim
            target: liquidFlow
            property: "t"
            from: 0
            to: 1
            duration: 260
            easing.type: Easing.InOutQuad
            onStopped: wsContainer.snapBubbleToActive()
        }

        Connections {
            target: liquidFlow
            function onTChanged() {
                wsContainer.updateBubbleFromFlow()
            }
        }

        Shape {
            id: liquidShape
            z: 0
            width: parent.width
            height: capsule.pillHeight
            visible: wsContainer.activePill !== null
            antialiasing: true

            ShapePath {
                fillColor: Theme.primary
                strokeWidth: 0
                PathSvg {
                    path: wsContainer.blobPath
                }
            }
        }

        Row {
            id: wsRow
            z: 1
            spacing: 6

            Repeater {
                model: capsule.targetWorkspaces

                Rectangle {
                    id: pill
                    property int wsId: modelData
                    property HyprlandWorkspace hyprWorkspace:
                        Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                    property bool isActive: hyprWorkspace?.active ?? false
                    property bool isUrgent: hyprWorkspace?.urgent ?? false

                    property var workspaceIcons: {
                        HyprlandData.windowList
                        return HyprlandData.iconsForWorkspace(wsId)
                    }
                    property bool isOccupied: workspaceIcons.length > 0
                        || (hyprWorkspace?.toplevels.values.length ?? 0) > 0

                    readonly property int iconSlot: 16
                    readonly property int iconSpacing: 3
                    readonly property int iconPadding: 6
                    readonly property int emptyPillWidth: 14
                    readonly property int iconsRowWidth: {
                        const n = workspaceIcons.length
                        if (n === 0)
                            return 0
                        return n * iconSlot + Math.max(0, n - 1) * iconSpacing + iconPadding * 2
                    }

                    height: capsule.pillHeight
                    radius: height / 2
                    clip: isOccupied
                    width: {
                        if (isOccupied)
                            return Math.max(iconSlot + iconPadding * 2, iconsRowWidth)
                        return emptyPillWidth
                    }

                    color: {
                        if (isActive)
                            return "transparent"
                        if (isUrgent)
                            return Theme.err
                        if (isOccupied)
                            return Theme.alpha(Theme.primary, 0.25)
                        return Theme.surfaceVariant
                    }

                    border.width: isActive ? 0 : Theme.barPillBorderWidth
                    border.color: Theme.barPillBorderColor()
                    opacity: isUrgent && !isActive ? urgentPulse.value : 1.0

                    onIsActiveChanged: {
                        if (isActive)
                            wsContainer.onPillActivated(pill)
                    }

                    Component.onCompleted: {
                        if (isActive)
                            wsContainer.onPillActivated(pill)
                    }

                    onWidthChanged: {
                        if (isActive)
                            wsContainer.onActivePillResized()
                    }

                    onXChanged: {
                        if (isActive && !liquidAnim.running)
                            wsContainer.snapBubbleToActive()
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuart
                        }
                    }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: pill.iconSpacing
                        visible: pill.isOccupied

                        Repeater {
                            model: pill.workspaceIcons

                            Item {
                                required property string modelData
                                width: pill.iconSlot
                                height: pill.iconSlot
                                implicitWidth: pill.iconSlot
                                implicitHeight: pill.iconSlot

                                Image {
                                    anchors.centerIn: parent
                                    width: pill.iconSlot
                                    height: pill.iconSlot
                                    source: modelData
                                    fillMode: Image.PreserveAspectFit
                                    sourceSize.width: pill.iconSlot * 2
                                    sourceSize.height: pill.iconSlot * 2
                                    mipmap: true
                                    smooth: true
                                    antialiasing: true
                                    opacity: pill.isActive ? 1 : 0.92
                                }
                            }
                        }
                    }

                    QtObject {
                        id: urgentPulse
                        property real value: 1.0
                    }

                    SequentialAnimation {
                        running: pill.isUrgent && !pill.isActive
                        loops: Animation.Infinite
                        NumberAnimation {
                            target: urgentPulse
                            property: "value"
                            from: 1.0; to: 0.45
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: urgentPulse
                            property: "value"
                            from: 0.45; to: 1.0
                            duration: 700
                            easing.type: Easing.InOutQuad
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch("focusmonitor " + capsule.outputName)
                            Hyprland.dispatch("workspace " + pill.wsId)
                        }
                    }
                }
            }
        }

        function onPillActivated(pill) {
            const switched = bubbleReady && activePill !== null && pill !== activePill
            activePill = pill

            if (!bubbleReady) {
                snapBubbleToActive()
                bubbleReady = true
                return
            }

            if (switched)
                startLiquidFlow()
            else
                snapBubbleToActive()
        }

        function onActivePillResized() {
            if (!activePill || liquidAnim.running)
                return
            snapBubbleToActive()
        }
    }
}
