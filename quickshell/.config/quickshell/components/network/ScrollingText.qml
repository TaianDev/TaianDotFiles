import QtQuick
import "../../core"

Item {
    id: root

    property string text:        ""
    property int    maxWidth:    60
    property color  color:       Theme.inkSurf
    property int    fontSize:    11
    property int    scrollSpeed: 38   // px/segundo

    // El Item siempre ocupa exactamente maxWidth — nunca más
    width:  maxWidth
    height: textItem.implicitHeight
    clip:   true

    readonly property bool needsScroll: textItem.implicitWidth > maxWidth

    Text {
        id: textItem
        text:           root.text
        color:          root.color
        font.pixelSize: root.fontSize
        y: 0

        // Animación de scroll: va de 0 a -(ancho + gap) en loop
        NumberAnimation on x {
            id: scrollAnim
            running:  root.needsScroll
            loops:    Animation.Infinite
            from:     0
            to:       -(textItem.implicitWidth + 20)
            duration: root.needsScroll
                ? ((textItem.implicitWidth + 20) / root.scrollSpeed * 1000)
                : 1000
        }

        // Reset de posición si el texto cambia o deja de necesitar scroll
        onImplicitWidthChanged: {
            if (!root.needsScroll) x = 0
        }
    }

    // Segunda copia para el efecto de loop continuo
    Text {
        visible:        root.needsScroll
        text:           root.text
        color:          root.color
        font.pixelSize: root.fontSize
        x:              textItem.x + textItem.implicitWidth + 20
        y:              0
    }
}
