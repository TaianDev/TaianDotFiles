import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    // Propiedades inyectadas desde el padre
    property color textMain: "#ffffff"
    property color textMuted: "#888888"
    property color accentGreen: "#b4db92"
    property color bgDark: "#1e1e1e"

    property int dYear: new Date().getFullYear()
    property int dMonth: new Date().getMonth()
    property var daysModel: []

    // Reiniciar a la fecha actual cuando el popup se abra
    Connections {
        target: popup  // el id del PanelWindow donde vive este Item
        function onIsOpenedChanged() {
            if (popup.isOpened) resetToToday()
        }
    }

    function resetToToday() {
        let today = new Date()
        dYear = today.getFullYear()
        dMonth = today.getMonth()
        updateCal()
    }

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

    // Modelos para los combos
    property var monthNames: [
        "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
        "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]
    property var yearModel: {
        let arr = []
        let currentYear = new Date().getFullYear()
        for (let y = currentYear - 50; y <= currentYear + 50; y++) arr.push(y)
        return arr
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // ─── Cabecera con selectores y botón "Hoy" ───
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Flecha anterior (área amplia, hover)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: prevArea.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    color: root.textMain
                    font.pixelSize: 22
                    font.bold: true
                }
                MouseArea {
                    id: prevArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.dMonth--
                        if (root.dMonth < 0) { root.dMonth = 11; root.dYear-- }
                        root.updateCal()
                    }
                }
            }

            // Selector de mes (ComboBox estilizado)
            ComboBox {
                id: monthCombo
                model: root.monthNames
                currentIndex: root.dMonth
                displayText: root.monthNames[root.dMonth]
                Layout.preferredWidth: 110
                background: Rectangle {
                    radius: 6
                    color: monthCombo.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
                    border.color: Qt.rgba(1,1,1,0.1)
                    border.width: 1
                }
                contentItem: Text {
                    text: monthCombo.displayText
                    color: root.textMain
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: Text {
                    text: "▾"
                    color: root.textMain
                    font.pixelSize: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                onActivated: {
                    root.dMonth = index
                    root.updateCal()
                }
            }

            // Selector de año (ComboBox estilizado)
            ComboBox {
                id: yearCombo
                model: root.yearModel
                currentIndex: root.yearModel.indexOf(root.dYear)
                displayText: root.dYear.toString()
                Layout.preferredWidth: 80
                background: Rectangle {
                    radius: 6
                    color: yearCombo.hovered ? Qt.rgba(1,1,1,0.1) : "transparent"
                    border.color: Qt.rgba(1,1,1,0.1)
                    border.width: 1
                }
                contentItem: Text {
                    text: yearCombo.displayText
                    color: root.textMain
                    font.pixelSize: 14
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
                indicator: Text {
                    text: "▾"
                    color: root.textMain
                    font.pixelSize: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                onActivated: {
                    root.dYear = yearCombo.currentText * 1
                    root.updateCal()
                }
            }

            // Flecha siguiente (área amplia, hover)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: nextArea.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "›"
                    color: root.textMain
                    font.pixelSize: 22
                    font.bold: true
                }
                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.dMonth++
                        if (root.dMonth > 11) { root.dMonth = 0; root.dYear++ }
                        root.updateCal()
                    }
                }
            }

            // Botón "Hoy" con icono de reloj
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: todayArea.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "🕐"   // icono de reloj
                    font.pixelSize: 18
                }
                MouseArea {
                    id: todayArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetToToday()
                }
            }
        }

        // ─── Días de la semana ───
        RowLayout {
            Layout.fillWidth: true
            Repeater {
                model: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sa", "Do"]
                Text {
                    Layout.fillWidth: true
                    text: modelData
                    color: root.textMuted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ─── Cuadrícula de días ───
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                model: root.daysModel
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8
                    property bool isToday: modelData.current && modelData.day === new Date().getDate() && root.dMonth === new Date().getMonth() && root.dYear === new Date().getFullYear()
                    color: isToday ? root.accentGreen : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: isToday ? root.bgDark : (modelData.current ? root.textMain : root.textMuted)
                        font.pixelSize: 14
                        font.bold: isToday
                    }
                }
            }
        }
    }
}