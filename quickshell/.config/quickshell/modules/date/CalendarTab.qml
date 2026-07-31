import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../core"

Item {
    id: root

    property color textMain: Theme.inkSurf
    property color textMuted: Theme.inkSurfVar
    property color accentGreen: Theme.primary
    property color bgDark: Theme.surface

    property int dYear: new Date().getFullYear()
    property int dMonth: new Date().getMonth()
    property var daysModel: []
    property var markedDates: []   // Almacena las fechas marcadas como "YYYY-MM-DD"

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
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    property var yearModel: {
        let arr = []
        let currentYear = new Date().getFullYear()
        for (let y = currentYear - 50; y <= currentYear + 50; y++) arr.push(y)
        return arr
    }

    // Función auxiliar para saber si un día está marcado
    function isMarked(day, isCurrentMonth) {
        if (!isCurrentMonth) return false
        let dateStr = dYear + "-" + String(dMonth+1).padStart(2,'0') + "-" + String(day).padStart(2,'0')
        return markedDates.includes(dateStr)
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

            // Selector de mes
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

            // Selector de año
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

            // Botón "Hoy" (icono de reloj)
            Rectangle {
                width: 36
                height: 36
                radius: 8
                color: todayArea.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "🕐"
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
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
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
                    id: dayCell
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 8

                    property bool isToday: modelData.current && modelData.day === new Date().getDate() && root.dMonth === new Date().getMonth() && root.dYear === new Date().getFullYear()
                    property bool cellHovered: false
                    property bool isMarked: root.isMarked(modelData.day, modelData.current)

                    color: isToday ? root.accentGreen : (cellHovered ? Qt.rgba(1,1,1,0.08) : "transparent")

                    // Número del día
                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: isToday ? root.bgDark : (modelData.current ? root.textMain : root.textMuted)
                        font.pixelSize: 14
                        font.bold: isToday
                        opacity: modelData.current ? 1 : 0.5
                    }

                    // Punto indicador de marca
                    Rectangle {
                        visible: dayCell.isMarked && modelData.current
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: root.accentGreen
                    }

                    // MouseArea para hover + doble clic (marcar/desmarcar)
                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton

                        onEntered: dayCell.cellHovered = true
                        onExited: dayCell.cellHovered = false

                        onDoubleClicked: {
                            // Solo marcamos días del mes actual
                            if (!modelData.current) return

                            let dateStr = root.dYear + "-" + String(root.dMonth+1).padStart(2,'0') + "-" + String(modelData.day).padStart(2,'0')
                            let newMarked = [...root.markedDates]
                            let idx = newMarked.indexOf(dateStr)
                            if (idx > -1) {
                                newMarked.splice(idx, 1)   // desmarcar
                            } else {
                                newMarked.push(dateStr)    // marcar
                            }
                            root.markedDates = newMarked
                        }
                    }
                }
            }
        }
    }
}