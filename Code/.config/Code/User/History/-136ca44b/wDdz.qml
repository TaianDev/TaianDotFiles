import Quickshell
import Quickshell.Io
import QtQuick 
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: principalPanel
    color: "transparent"
    focusable: true
    anchors {
        left: false; right: false; top: false; bottom: false
    }
    implicitWidth: principalPanel.screen.width * 0.25
    implicitHeight: principalPanel.screen.height * 0.23

    Rectangle {
        id: topPanel
        anchors.fill: parent
        radius: topPanel.height * 0.06
        color: "#ffffff"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: topPanel.width * 0.03
            spacing: topPanel.height * 0.06 
        
            RowLayout {
                Layout.fillWidth: true 
                spacing: topPanel.width * 0.03

                SelectorTranslate {
                    id: sourceLanguageSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    optionsList: ["English", "Spanish", "French", "German", "Chinese", "Automatic Detection"]
                }

                Rectangle {
                    id: languageSwitcher
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.1
                    radius: topPanel.height * 0.03
                    color: '#8cf0c3'
                }

                SelectorTranslate {
                    id: targetLanguageSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    optionsList: ["English", "Spanish", "French", "German", "Chinese", "Automatic Detection"]
                }

                SelectorTranslate {
                    id: translationEngineSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    optionsList: ["Google", "Bing", "Yandex"]
                }
            }
            
            Rectangle {
                id: translateTextWindow
                Layout.fillWidth: true  
                Layout.fillHeight: true 
                radius: topPanel.height * 0.03
                color: '#8cf0c3'
            }
        }
    }
}