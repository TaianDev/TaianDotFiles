pragma Singleton
import QtQuick

QtObject {
    // ─── FONDOS PRINCIPALES (El alma del look de imagen.jpg) ───
    // Base profunda, oscura pero inundada del color del wallpaper (Fondo de ventanas)
    readonly property color background: "#1e1f25"
    
    // Superficie ligeramente más clara/vibrante para paneles internos, barras laterales o inputs
    readonly property color surface: "#282a2f"
    readonly property color surfaceHeader: "#33353a"

    // ─── TEXTO Y LEGIBILIDAD ───
    // Blanco tiza / lavanda pálido para máxima legibilidad sobre fondos oscuros
    readonly property color onBackground: "#e2e2e9"
    // Texto secundario o descriptivo (más tenue)
    readonly property color onBackgroundMuted: "#c4c6d0"

    // ─── ACENTOS VIBRANTES (Para botones activos, badges y selección) ───
    // El lavanda pastel brillante que vemos en los botones destacados de la imagen
    readonly property color primary: "#adc6ff"
    readonly property color onPrimary: "#112f60"
    
    // Contenedores secundarios (como pastillas de estados o botones secundarios)
    readonly property color primaryContainer: "#2b4678"
    readonly property color onPrimaryContainer: "#d8e2ff"

    // ─── TONOS SECUNDARIOS Y CONTRASSTE (Detalles finos) ───
    readonly property color secondary: "#bfc6dc"
    readonly property color onSecondary: "#293041"
    readonly property color tertiary: "#debcdf"

    // ─── BORDES Y SEPARADORES (Crucial para el look refinado de las ventanas) ───
    // Líneas divisorias sutiles que delimitan los componentes sin sobrecargar
    readonly property color outline: "#44474f"
    // Borde enfocado o activo
    readonly property color outlineActive: "#8e9099"

    // ─── ESTADOS DE ERROR / ALERTAS ───
    readonly property color error: "#ffb4ab"
    readonly property color onError: "#690005"
}
