// Archivo: SelectorDesplegable.qml
import QtQuick
import QtQuick.Controls

Rectangle {
    property var listaOpciones: []
    radius: height * 0.15 
    color: '#8cf0c3'

    ComboBox {
        anchors.fill: parent
        editable: true
        model: listaOpciones
        background: Item {}
    }
}