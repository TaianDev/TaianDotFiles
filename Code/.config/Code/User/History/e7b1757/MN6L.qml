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
                text: new Date(root.dYear, root.dMonth).toLocaleString(Qt.locale(), "MMMM yyyy")
                color: root.textMain
                font.pixelSize: 18
                font.bold: true
                font.capitalization: Font.Capitalize
            }
            Button {
                text: "‹"
                background: Item {}
                contentItem: Text { text: parent.text; color: root.textMain; font.pixelSize: 18 }
                onClicked: {
                    root.dMonth--
                    if (root.dMonth < 0) { root.dMonth = 11; root.dYear-- }
                    root.updateCal()
                }
            }
            Button {
                text: "›"
                background: Item {}
                contentItem: Text { text: parent.text; color: root.textMain; font.pixelSize: 18 }
                onClicked: {
                    root.dMonth++
                    if (root.dMonth > 11) { root.dMonth = 0; root.dYear++ }
                    root.updateCal()
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
                    color: root.textMuted
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