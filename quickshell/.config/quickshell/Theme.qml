pragma Singleton
import QtQuick

QtObject {
    // ─── BACKGROUND & SURFACE (Fondos principales, paneles y tarjetas) ───
    readonly property color background: "#111318"
    readonly property color onBackground: "#e2e2e9"
    readonly property color surface: "#111318"
    readonly property color onSurface: "#e2e2e9"
    readonly property color surfaceVariant: "#44474f"
    readonly property color onSurfaceVariant: "#c4c6d0"
    
    // ─── PRIMARY (Acento principal: botones, barras activas, selecciones) ───
    readonly property color primary: "#adc6ff"
    readonly property color onPrimary: "#112f60"
    readonly property color primaryContainer: "#2b4678"
    readonly property color onPrimaryContainer: "#d8e2ff"
    
    // ─── SECONDARY (Acento suave: elementos de UI menos destacables) ───
    readonly property color secondary: "#bfc6dc"
    readonly property color onSecondary: "#293041"
    readonly property color secondaryContainer: "#3f4759"
    readonly property color onSecondaryContainer: "#dbe2f9"
    
    // ─── TERTIARY (Contraste vibrante: switches, badges, iconos destacados) ───
    readonly property color tertiary: "#debcdf"
    readonly property color onTertiary: "#402843"
    readonly property color tertiaryContainer: "#583e5b"
    readonly property color onTertiaryContainer: "#fcd7fb"

    // ─── ERROR (Acciones destructivas: eliminar, alertas, cancelar) ───
    readonly property color error: "#ffb4ab"
    readonly property color onError: "#690005"
    readonly property color errorContainer: "#93000a"
    readonly property color onErrorContainer: "#ffdad6"
    
    // ─── EXTRAS (Bordes, divisores y sombras) ───
    readonly property color outline: "#8e9099"
    readonly property color outlineVariant: "#44474f"
    readonly property color shadow: "#000000"
}
