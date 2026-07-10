pragma Singleton
import QtQuick

QtObject {
    // ─── FONDOS PRINCIPALES (El alma del look de imagen.jpg) ───
    // Base profunda, oscura pero inundada del color del wallpaper (Fondo de ventanas)
    readonly property color background: "{{colors.surface_container.default.hex}}"
    
    // Superficie ligeramente más clara/vibrante para paneles internos, barras laterales o inputs
    readonly property color surface: "{{colors.surface_container_high.default.hex}}"
    readonly property color surfaceHeader: "{{colors.surface_container_highest.default.hex}}"

    // ─── TEXTO Y LEGIBILIDAD ───
    // Blanco tiza / lavanda pálido para máxima legibilidad sobre fondos oscuros
    readonly property color onBackground: "{{colors.on_surface.default.hex}}"
    // Texto secundario o descriptivo (más tenue)
    readonly property color onBackgroundMuted: "{{colors.on_surface_variant.default.hex}}"

    // ─── ACENTOS VIBRANTES (Para botones activos, badges y selección) ───
    // El lavanda pastel brillante que vemos en los botones destacados de la imagen
    readonly property color primary: "{{colors.primary.default.hex}}"
    readonly property color onPrimary: "{{colors.on_primary.default.hex}}"
    
    // Contenedores secundarios (como pastillas de estados o botones secundarios)
    readonly property color primaryContainer: "{{colors.primary_container.default.hex}}"
    readonly property color onPrimaryContainer: "{{colors.on_primary_container.default.hex}}"

    // ─── TONOS SECUNDARIOS Y CONTRASSTE (Detalles finos) ───
    readonly property color secondary: "{{colors.secondary.default.hex}}"
    readonly property color onSecondary: "{{colors.on_secondary.default.hex}}"
    readonly property color tertiary: "{{colors.tertiary.default.hex}}"

    // ─── BORDES Y SEPARADORES (Crucial para el look refinado de las ventanas) ───
    // Líneas divisorias sutiles que delimitan los componentes sin sobrecargar
    readonly property color outline: "{{colors.outline_variant.default.hex}}"
    // Borde enfocado o activo
    readonly property color outlineActive: "{{colors.outline.default.hex}}"

    // ─── ESTADOS DE ERROR / ALERTAS ───
    readonly property color error: "{{colors.error.default.hex}}"
    readonly property color onError: "{{colors.on_error.default.hex}}"
}
