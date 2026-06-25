import Quickshell
import Quickshell.Io
import QtQuick 
import QtQuick.Layouts

PanelWindow {
    id: principalPanel
    color: "transparent"
    anchors {
        left: false; right: false; top: false; bottom: false
    }
    implicitWidth: principalPanel.screen.width * 0.25
    implicitHeight: principalPanel.screen.height * 0.23

    Rectangle {
        id: topPanel
        anchors.fill: parent
        radius: 15
        color: "#ffffff"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15 
        
            RowLayout {
                Layout.fillWidth: true 
                spacing: 14

                Rectangle {
                    id: languageSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    radius: 7
                    color: '#8cf0c3'
                }

                Rectangle {
                    id: languageSwitcher
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.1
                    radius: 7
                    color: '#8cf0c3'
                }

                Rectangle {
                    id: languageSelector1
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    radius: 7
                    color: '#8cf0c3'
                }

                Rectangle {
                    id: languageSelector2
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    radius: 7
                    color: '#8cf0c3'
                }
            }
            
            Rectangle {
                id: translateTextWindow
                Layout.fillWidth: true  
                Layout.fillHeight: true 
                radius: 7
                color: '#8cf0c3'
            }
        }
    }
}



