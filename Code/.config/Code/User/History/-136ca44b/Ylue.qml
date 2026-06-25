// Archivo: principalPanel.qml
import Quickshell
import Quickshell.Io
import QtQuick 
import QtQuick.Layouts
import QtQuick.Controls
import "selectorTranslate.qml" // Asegúrate de que la ruta sea correcta`

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

                // 1. Selector de Idioma de Origen
                selectorTranslate {
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    listaOpciones: ["English", "Spanish", "French", "German", "Chinese", "Automatic Detection"]
                }

                // Botón de Intercambio (Aún es un Rectangle simple, pero podrías modularizarlo después)
                Rectangle {
                    id: languageSwitcher
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.1
                    radius: topPanel.height * 0.03
                    color: '#8cf0c3'
                }

                // 2. Selector de Idioma de Destino
                selectorTranslate {
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    listaOpciones: ["English", "Spanish", "French", "German", "Chinese", "Automatic Detection"]
                }

                // 3. Selector de Motor de Traducción
                selectorTranslate {
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    listaOpciones: ["Google", "Bing", "Yandex"]
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