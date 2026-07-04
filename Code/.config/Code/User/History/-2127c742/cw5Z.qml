import QtQuick
import Qt5Compat.GraphicalEffects

Row {
    id: root
    spacing: 6
    
    // Propiedades personalizables al llamar al módulo
    property int value: 0
    property string iconPath: ""
    property color activeColor: "#b4a7f5" // Un tono lila por defecto
    property string suffix: ""

    // Redibujamos el círculo cada vez que el valor cambia
    onValueChanged: canvas.requestPaint()

    // ── 1. Indicador Circular ──
    Item {
        width: 22
        height: 22
        anchors.verticalCenter: parent.verticalCenter

        Canvas {
            id: canvas
            anchors.fill: parent
            
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var radius = (width / 2) - 2;
                var centerX = width / 2;
                var centerY = height / 2;

                // Anillo de fondo (semitransparente)
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                ctx.lineWidth = 2;
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.15);
                ctx.stroke();

                // Arco de Progreso
                if (root.value > 0) {
                    ctx.beginPath();
                    // Empezamos arriba a las 12 en punto (-90 grados)
                    var startAngle = -Math.PI / 2;
                    var endAngle = startAngle + (Math.min(root.value, 100) / 100) * 2 * Math.PI;
                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                    ctx.lineWidth = 2;
                    ctx.lineCap = "round"; // Bordes redondeados en la línea
                    ctx.strokeStyle = root.activeColor;
                    ctx.stroke();
                }
            }
        }

        // ── Icono Central ──
        Image {
            id: icn
            anchors.centerIn: parent
            width: 12
            height: 12
            source: root.iconPath
            sourceSize.width: 12
            sourceSize.height: 12
            fillMode: Image.PreserveAspectFit
            visible: false // Oculto porque ColorOverlay lo pinta
        }

        ColorOverlay {
            anchors.fill: icn
            source: icn
            color: "#ffffff" // Forzamos a que el SVG sea blanco
        }
    }

    // ── 2. Texto Numérico ──
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value + root.suffix
        color: "#ffffff"
        font.pixelSize: 13
        font.bold: true
    }
}