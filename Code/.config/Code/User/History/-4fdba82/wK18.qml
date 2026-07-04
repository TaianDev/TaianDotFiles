import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popup
    color: "transparent"

    implicitWidth: 480
    implicitHeight: 360

    // Anclaje y márgenes correctos
    anchors {
        top: true
        right: true
        topMargin: 48
        rightMargin: 16
    }
    exclusiveZone: 0

    WlrLayershell.namespace: "date_popup"
    WlrLayershell.layer: WlrLayer.Top

    property bool isOpened: false
    property int currentTab: 0

    property color bgDark: "#1e1e1e"
    property color bgLighter: "#2d2d2d"
    property color accentGreen: "#b4db92"
    property color textMain: "#ffffff"
    property color textMuted: "#888888"

    visible: isOpened || slideAnim.running

    Item {
        id: mainWrapper
        anchors.fill: parent

        y: popup.isOpened ? 0 : -20
        opacity: popup.isOpened ? 1 : 0
        Behavior on y { NumberAnimation { id: slideAnim; duration: 250; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            color: popup.bgDark
            radius: 16
            border.color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ─── BARRA LATERAL ───
                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.fillHeight: true
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        Repeater {
                            model: [
                                { name: "Calendario", icon: "📅", index: 0 },
                                { name: "Cronómetro", icon: "⏱️", index: 1 },
                                { name: "Temporizador", icon: "⏳", index: 2 }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                radius: 12
                                color: popup.currentTab === modelData.index ? Qt.rgba(180/255, 219/255, 146/255, 0.15)
                                                                              : (btnMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        font.pixelSize: 18
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.name
                                        color: popup.currentTab === modelData.index ? popup.textMain : popup.textMuted
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: btnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.currentTab = modelData.index
                                }
                            }
                        }
                        Item { Layout.fillHeight: true }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 1
                        height: parent.height
                        color: Qt.rgba(1, 1, 1, 0.05)
                    }
                }

                // ─── CONTENIDO DE PESTAÑAS ───
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: popup.currentTab

                    // 🗂️ CALENDARIO
                    Item {
                        id: calendarTab
                        property int dYear: new Date().getFullYear()
                        property int dMonth: new Date().getMonth()
                        property var daysModel: []

                        function updateCal() {
                            let temp = []
                            let firstDay = new Date(dYear, dMonth, 1).getDay()
                            firstDay = firstDay === 0 ? 6 : firstDay - 1
                            let daysInMonth = new Date(dYear, dMonth + 1, 0).getDate()
                            let daysPrev = new Date(dYear, dMonth, 0).getDate()

                            for (let i = firstDay - 1; i >= 0; i--) temp.push({day: daysPrev - i, current: false})
                            for (let i = 1; i <= daysInMonth; i++) temp.push({day: i, current: true})
                            let rem = 42 - temp.length
                            for (let i = 1; i <= rem; i++) temp.push({day: i, current: false})
                            daysModel = temp
                        }

                        Component.onCompleted: updateCal()

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: new Date(calendarTab.dYear, calendarTab.dMonth).toLocaleString(Qt.locale(), "MMMM yyyy")
                                    color: popup.textMain
                                    font.pixelSize: 18
                                    font.bold: true
                                    font.capitalization: Font.Capitalize
                                }
                                Button {
                                    text: "‹"
                                    background: Item {}
                                    contentItem: Text { text: parent.text; color: popup.textMain; font.pixelSize: 18 }
                                    onClicked: {
                                        calendarTab.dMonth--
                                        if (calendarTab.dMonth < 0) {
                                            calendarTab.dMonth = 11
                                            calendarTab.dYear--
                                        }
                                        calendarTab.updateCal()
                                    }
                                }
                                Button {
                                    text: "›"
                                    background: Item {}
                                    contentItem: Text { text: parent.text; color: popup.textMain; font.pixelSize: 18 }
                                    onClicked: {
                                        calendarTab.dMonth++
                                        if (calendarTab.dMonth > 11) {
                                            calendarTab.dMonth = 0
                                            calendarTab.dYear++
                                        }
                                        calendarTab.updateCal()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Repeater {
                                    model: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sa", "Do"]
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData
                                        color: popup.textMuted
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                columns: 7
                                rowSpacing: 8
                                columnSpacing: 8

                                Repeater {
                                    model: calendarTab.daysModel
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 8
                                        property bool isToday: modelData.current
                                                             && modelData.day === new Date().getDate()
                                                             && calendarTab.dMonth === new Date().getMonth()
                                                             && calendarTab.dYear === new Date().getFullYear()
                                        color: isToday ? popup.accentGreen : "transparent"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            color: isToday ? popup.bgDark : (modelData.current ? popup.textMain : popup.textMuted)
                                            font.pixelSize: 14
                                            font.bold: isToday
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ⏱️ CRONÓMETRO
                    Item {
                        id: stopwatchTab
                        property int elapsedMs: 0
                        property bool running: false

                        Timer {
                            interval: 50
                            running: stopwatchTab.running
                            repeat: true
                            onTriggered: stopwatchTab.elapsedMs += 50
                        }

                        function formatSW(ms) {
                            let h = Math.floor(ms / 3600000).toString().padStart(2, '0')
                            let m = Math.floor((ms % 3600000) / 60000).toString().padStart(2, '0')
                            let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
                            let d = Math.floor((ms % 1000) / 100)
                            return h + ":" + m + ":" + s + "." + d
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 30

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: stopwatchTab.formatSW(stopwatchTab.elapsedMs)
                                color: popup.textMain
                                font.pixelSize: 48
                                font.weight: Font.Thin
                                style: Text.Outline
                                styleColor: Qt.rgba(1, 1, 1, 0.2)
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 16

                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 24
                                    color: popup.bgLighter
                                    Text {
                                        anchors.centerIn: parent
                                        text: stopwatchTab.running ? "⏸" : "▶"
                                        color: popup.textMain
                                        font.pixelSize: 20
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: stopwatchTab.running = !stopwatchTab.running
                                    }
                                }

                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 24
                                    color: popup.bgLighter
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⏹"
                                        color: popup.textMain
                                        font.pixelSize: 20
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            stopwatchTab.running = false
                                            stopwatchTab.elapsedMs = 0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ⏳ TEMPORIZADOR
                    Item {
                        id: timerTab
                        property int h: 0
                        property int m: 0
                        property int s: 0
                        property int totalSecs: 0
                        property bool running: false

                        Timer {
                            interval: 1000
                            running: timerTab.running
                            repeat: true
                            onTriggered: {
                                if (timerTab.totalSecs > 0) timerTab.totalSecs--
                                else timerTab.running = false
                            }
                        }

                        function setQuick(mins) {
                            running = false
                            h = Math.floor(mins / 60)
                            m = mins % 60
                            s = 0
                            totalSecs = h * 3600 + m * 60 + s
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            // Configuración
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: !timerTab.running

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 16

                                    Text {
                                        text: "Inicio rápido"
                                        color: popup.textMain
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    GridLayout {
                                        columns: 4
                                        columnSpacing: 8
                                        rowSpacing: 8
                                        Layout.alignment: Qt.AlignHCenter
                                        Repeater {
                                            model: [1, 2, 3, 5, 10, 15, 30, 60]
                                            Rectangle {
                                                width: 50
                                                height: 32
                                                radius: 8
                                                color: popup.bgLighter
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData === 60 ? "1 h" : modelData + " m"
                                                    color: popup.textMain
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: timerTab.setQuick(modelData)
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Establecer temporizador"
                                        color: popup.textMain
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: 10
                                    }

                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 12

                                        Repeater {
                                            model: 3
                                            Rectangle {
                                                width: 60
                                                height: 90
                                                radius: 8
                                                color: popup.bgLighter

                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    Text {
                                                        text: "+"
                                                        color: popup.textMain
                                                        font.pixelSize: 18
                                                        Layout.alignment: Qt.AlignHCenter
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (index === 0) timerTab.h++
                                                                else if (index === 1) timerTab.m = (timerTab.m + 1) % 60
                                                                else timerTab.s = (timerTab.s + 1) % 60
                                                                timerTab.totalSecs = timerTab.h * 3600 + timerTab.m * 60 + timerTab.s
                                                            }
                                                        }
                                                    }
                                                    Text {
                                                        text: {
                                                            if (index === 0) return timerTab.h.toString().padStart(2, '0')
                                                            if (index === 1) return timerTab.m.toString().padStart(2, '0')
                                                            return timerTab.s.toString().padStart(2, '0')
                                                        }
                                                        color: popup.textMain
                                                        font.pixelSize: 28
                                                        Layout.alignment: Qt.AlignHCenter
                                                    }
                                                    Text {
                                                        text: "-"
                                                        color: popup.textMain
                                                        font.pixelSize: 18
                                                        Layout.alignment: Qt.AlignHCenter
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                if (index === 0 && timerTab.h > 0) timerTab.h--
                                                                else if (index === 1 && timerTab.m > 0) timerTab.m--
                                                                else if (index === 2 && timerTab.s > 0) timerTab.s--
                                                                timerTab.totalSecs = timerTab.h * 3600 + timerTab.m * 60 + timerTab.s
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.topMargin: 10
                                        width: 120
                                        height: 40
                                        radius: 20
                                        color: "#7287a3"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Empezar"
                                            color: "#ffffff"
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (timerTab.totalSecs > 0) timerTab.running = true
                                            }
                                        }
                                    }
                                }
                            }

                            // Cuenta regresiva
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: timerTab.running

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 30

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Math.floor(timerTab.totalSecs / 3600).toString().padStart(2, '0') + ":" +
                                              Math.floor((timerTab.totalSecs % 3600) / 60).toString().padStart(2, '0') + ":" +
                                              (timerTab.totalSecs % 60).toString().padStart(2, '0')
                                        color: popup.textMain
                                        font.pixelSize: 54
                                        font.weight: Font.Thin
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 120
                                        height: 40
                                        radius: 20
                                        color: "#e06c75"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "Cancelar"
                                            color: "#ffffff"
                                            font.bold: true
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                timerTab.running = false
                                                timerTab.totalSecs = 0
                                                timerTab.h = 0
                                                timerTab.m = 0
                                                timerTab.s = 0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}