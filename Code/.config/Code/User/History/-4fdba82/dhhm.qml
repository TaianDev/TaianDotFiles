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
    
    // Anclaje Wayland a prueba de fallos (Esquina superior derecha)
    anchors { top: true; right: true }
    topMargin: 48  // Baja un poco para no tapar tu barra
    rightMargin: 16
    exclusiveZone: 0 
    
    WlrLayershell.namespace: "date_popup"
    WlrLayershell.layer: WlrLayer.Top

    property bool isOpened: false
    property int currentTab: 0 // 0=Calendar, 1=Stopwatch, 2=Timer
    
    // Paleta de colores extraída de tus imágenes
    property color bgDark: "#1e1e1e"
    property color bgLighter: "#2d2d2d"
    property color accentGreen: "#b4db92"
    property color textMain: "#ffffff"
    property color textMuted: "#888888"

    visible: isOpened || slideAnim.running

    Item {
        id: mainWrapper
        anchors.fill: parent
        
        // Animación Slide y Fade
        y: popup.isOpened ? 0 : -20
        opacity: popup.isOpened ? 1 : 0
        Behavior on y { NumberAnimation { id: slideAnim; duration: 250; easing.type: Easing.OutQuart } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.fill: parent
            color: popup.bgDark
            radius: 16
            border.color: Qt.rgba(1,1,1,0.05)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // ─── 1. BARRA LATERAL (SIDEBAR) ───
                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.fillHeight: true
                    color: "transparent"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        // Selector de Iconos estilo Switcher
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
                                color: popup.currentTab === modelData.index ? Qt.rgba(180/255, 219/255, 146/255, 0.15) : (btnMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent")
                                
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
                        Item { Layout.fillHeight: true } // Espaciador
                    }
                    
                    // Divisor vertical
                    Rectangle {
                        anchors.right: parent.right
                        width: 1; height: parent.height
                        color: Qt.rgba(1,1,1,0.05)
                    }
                }

                // ─── 2. CONTENIDO PRINCIPAL (PESTAÑAS) ───
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: popup.currentTab

                    // 🗂️ PESTAÑA 0: CALENDARIO
                    Item {
                        property int dYear: new Date().getFullYear()
                        property int dMonth: new Date().getMonth()
                        property var daysModel: []

                        function updateCal() {
                            let temp = []
                            let firstDay = new Date(dYear, dMonth, 1).getDay()
                            firstDay = firstDay === 0 ? 6 : firstDay - 1 // Lunes=0
                            let daysInMonth = new Date(dYear, dMonth + 1, 0).getDate()
                            let daysPrev = new Date(dYear, dMonth, 0).getDate()
                            
                            for(let i=firstDay-1; i>=0; i--) temp.push({day: daysPrev-i, current: false})
                            for(let i=1; i<=daysInMonth; i++) temp.push({day: i, current: true})
                            let rem = 42 - temp.length
                            for(let i=1; i<=rem; i++) temp.push({day: i, current: false})
                            daysModel = temp
                        }

                        Component.onCompleted: updateCal()

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 12

                            // Cabecera (Mes/Año)
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: new Date(parent.parent.dYear, parent.parent.dMonth).toLocaleString(Qt.locale(), "MMMM yyyy")
                                    color: popup.textMain
                                    font.pixelSize: 18
                                    font.bold: true
                                    font.capitalization: Font.Capitalize
                                }
                                Button { text: "‹"; background: Item{}; contentItem: Text { text: parent.text; color: popup.textMain; font.pixelSize: 18 }; onClicked: { parent.parent.dMonth--; if(parent.parent.dMonth < 0){ parent.parent.dMonth=11; parent.parent.dYear-- }; parent.parent.updateCal() } }
                                Button { text: "›"; background: Item{}; contentItem: Text { text: parent.text; color: popup.textMain; font.pixelSize: 18 }; onClicked: { parent.parent.dMonth++; if(parent.parent.dMonth > 11){ parent.parent.dMonth=0; parent.parent.dYear++ }; parent.parent.updateCal() } }
                            }

                            // Días de la semana
                            RowLayout {
                                Layout.fillWidth: true
                                Repeater {
                                    model: ["Lu", "Ma", "Mi", "Ju", "Vi", "Sa", "Do"]
                                    Text { Layout.fillWidth: true; text: modelData; color: popup.textMuted; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter }
                                }
                            }

                            // Cuadrícula de días
                            GridLayout {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                columns: 7
                                rowSpacing: 8; columnSpacing: 8
                                Repeater {
                                    model: parent.parent.daysModel
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        radius: 8
                                        property bool isToday: modelData.current && modelData.day === new Date().getDate() && parent.parent.parent.dMonth === new Date().getMonth() && parent.parent.parent.dYear === new Date().getFullYear()
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

                    // ⏱️ PESTAÑA 1: CRONÓMETRO
                    Item {
                        property int elapsedMs: 0
                        property bool running: false

                        Timer {
                            interval: 50 // Se actualiza rápido para los milisegundos
                            running: parent.running; repeat: true
                            onTriggered: parent.elapsedMs += 50
                        }

                        function formatSW(ms) {
                            let h = Math.floor(ms / 3600000).toString().padStart(2, '0')
                            let m = Math.floor((ms % 3600000) / 60000).toString().padStart(2, '0')
                            let s = Math.floor((ms % 60000) / 1000).toString().padStart(2, '0')
                            let d = Math.floor((ms % 1000) / 100) // Décimas
                            return h + ":" + m + ":" + s + "." + d
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 30

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: parent.parent.formatSW(parent.parent.elapsedMs)
                                color: popup.textMain
                                font.pixelSize: 48
                                font.weight: Font.Thin
                                style: Text.Outline; styleColor: Qt.rgba(1,1,1,0.2)
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 16
                                // Play / Pause
                                Rectangle {
                                    width: 48; height: 48; radius: 24; color: popup.bgLighter
                                    Text { anchors.centerIn: parent; text: parent.parent.parent.running ? "⏸" : "▶"; color: popup.textMain; font.pixelSize: 20 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.parent.running = !parent.parent.parent.running }
                                }
                                // Reset
                                Rectangle {
                                    width: 48; height: 48; radius: 24; color: popup.bgLighter
                                    Text { anchors.centerIn: parent; text: "⏹"; color: popup.textMain; font.pixelSize: 20 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { parent.parent.parent.running = false; parent.parent.parent.elapsedMs = 0 } }
                                }
                            }
                        }
                    }

                    // ⏳ PESTAÑA 2: TEMPORIZADOR
                    Item {
                        property int h: 0; property int m: 0; property int s: 0
                        property int totalSecs: 0
                        property bool running: false

                        Timer {
                            interval: 1000; running: parent.running; repeat: true
                            onTriggered: {
                                if (parent.totalSecs > 0) parent.totalSecs--
                                else parent.running = false
                            }
                        }

                        function setQuick(mins) {
                            running = false
                            h = Math.floor(mins / 60); m = mins % 60; s = 0
                            totalSecs = h*3600 + m*60 + s
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            // Estado: Configurando (Muestra botones y controles)
                            Item {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                visible: !parent.parent.running

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 16
                                    
                                    Text { text: "Inicio rápido"; color: popup.textMain; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                    
                                    GridLayout {
                                        columns: 4; columnSpacing: 8; rowSpacing: 8; Layout.alignment: Qt.AlignHCenter
                                        Repeater {
                                            model: [1, 2, 3, 5, 10, 15, 30, 60]
                                            Rectangle {
                                                width: 50; height: 32; radius: 8; color: popup.bgLighter
                                                Text { anchors.centerIn: parent; text: (modelData===60 ? "1 h" : modelData + " m"); color: popup.textMain }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.parent.parent.parent.setQuick(modelData) }
                                            }
                                        }
                                    }

                                    Text { text: "Establecer temporizador"; color: popup.textMain; font.bold: true; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10 }
                                    
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 12
                                        // Componente de controles +/-
                                        Repeater {
                                            model: [ {val: parent.parent.parent.h, max: 99}, {val: parent.parent.parent.m, max: 59}, {val: parent.parent.parent.s, max: 59} ]
                                            Rectangle {
                                                width: 60; height: 90; radius: 8; color: popup.bgLighter
                                                ColumnLayout {
                                                    anchors.fill: parent
                                                    Text { text: "+"; color: popup.textMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter; MouseArea { anchors.fill: parent; onClicked: { if(index===0) parent.parent.parent.parent.h++; else if(index===1) parent.parent.parent.parent.m=(parent.parent.parent.parent.m+1)%60; else parent.parent.parent.parent.s=(parent.parent.parent.parent.s+1)%60; parent.parent.parent.parent.totalSecs = parent.parent.parent.parent.h*3600 + parent.parent.parent.parent.m*60 + parent.parent.parent.parent.s } } }
                                                    Text { text: modelData.val.toString().padStart(2, '0'); color: popup.textMain; font.pixelSize: 28; Layout.alignment: Qt.AlignHCenter }
                                                    Text { text: "-"; color: popup.textMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter; MouseArea { anchors.fill: parent; onClicked: { if(index===0 && parent.parent.parent.parent.h>0) parent.parent.parent.parent.h--; else if(index===1 && parent.parent.parent.parent.m>0) parent.parent.parent.parent.m--; else if(index===2 && parent.parent.parent.parent.s>0) parent.parent.parent.parent.s--; parent.parent.parent.parent.totalSecs = parent.parent.parent.parent.h*3600 + parent.parent.parent.parent.m*60 + parent.parent.parent.parent.s } } }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10
                                        width: 120; height: 40; radius: 20
                                        color: "#7287a3" // Color púrpura/azulado de tu captura "Empezar"
                                        Text { anchors.centerIn: parent; text: "Empezar"; color: "#ffffff"; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if(parent.parent.parent.totalSecs > 0) parent.parent.parent.running = true } }
                                    }
                                }
                            }

                            // Estado: Corriendo (Muestra la cuenta regresiva)
                            Item {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                visible: parent.parent.running
                                
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 30
                                    
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Math.floor(parent.parent.parent.totalSecs/3600).toString().padStart(2,'0') + ":" + Math.floor((parent.parent.parent.totalSecs%3600)/60).toString().padStart(2,'0') + ":" + (parent.parent.parent.totalSecs%60).toString().padStart(2,'0')
                                        color: popup.textMain; font.pixelSize: 54; font.weight: Font.Thin
                                    }

                                    Rectangle {
                                        Layout.alignment: Qt.AlignHCenter
                                        width: 120; height: 40; radius: 20; color: "#e06c75" // Botón de cancelar rojizo
                                        Text { anchors.centerIn: parent; text: "Cancelar"; color: "#ffffff"; font.bold: true }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { parent.parent.parent.running = false; parent.parent.parent.totalSecs = 0; parent.parent.parent.h=0; parent.parent.parent.m=0; parent.parent.parent.s=0 } }
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