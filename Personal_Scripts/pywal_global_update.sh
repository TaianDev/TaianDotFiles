#!/usr/bin/env bash

# Un script para aplicar un nuevo tema a todas las aplicaciones relevantes.

# Eliminamos 'set -e' para evitar que el script muera si pkill o killall no encuentran procesos.

if [ -z "$1" ]; then
  echo "No wallpaper path provided. Won't update pywal and walcord colors."
  exit 1
fi

WALLPAPER_PATH="$1"
echo "Setting new theme from: $WALLPAPER_PATH"

# 1. ACTUALIZAR ESTADO
# Hacemos el enlace simbólico primero, es una operación casi instantánea.
ln -sf "$WALLPAPER_PATH" "$HOME/.config/hypr/current_wall"

# 2. GENERACIÓN DE RECURSOS (Bloqueante)
# Generamos los colores con wal y matugen, y la imagen de Rofi.
# Esto debe terminar ANTES de recargar las apps, para que lean los archivos correctos.
wal -qste -i "$WALLPAPER_PATH"
matugen image "$WALLPAPER_PATH"

magick "$WALLPAPER_PATH" \
  -resize 1280x720^ \
  -gravity center \
  -extent 1280x720 \
  -strip \
  -sampling-factor 4:2:0 \
  -quality 20 \
  "$HOME/.config/rofi/rofi_bg.jpg"

# 3. APLICAR FONDO DE PANTALLA
# Añadimos '&' al final para enviarlo al fondo (background).
# Así la animación de 2 segundos ocurre MIENTRAS el script recarga el resto de la interfaz.
swww img "$WALLPAPER_PATH" --transition-type wave --transition-fps 60 --transition-duration 2 &

# 4. RECARGAR APLICACIONES
# Ahora que los colores existen y el fondo se está animando, recargamos la UI.
swaync-client -rs

# Usamos '|| true' para absorber el error si el proceso no existe y que bash no se queje.
pkill hyprwave || true
hyprwave &
disown

killall -SIGUSR1 kitty || true

echo "==> Theme update complete!"
