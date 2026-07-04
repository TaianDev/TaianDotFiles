#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "No wallpaper path provided. Won't update pywal and walcord colors."
  exit 1
fi

WALLPAPER_PATH="$1"

# 1. ACTUALIZAR ESTADO
# Hacemos el enlace simbólico primero, es una operación casi instantánea.
ln -sf "$WALLPAPER_PATH" "$HOME/.config/hypr/current_wall"

# 2. GENERACIÓN DE RECURSOS (Bloqueante)
wal -qste -i "$WALLPAPER_PATH"
matugen image "$WALLPAPER_PATH" --source-color-index 0

magick "$WALLPAPER_PATH" \
  -resize 1280x720^ \
  -gravity center \
  -extent 1280x720 \
  -strip \
  -sampling-factor 4:2:0 \
  -quality 20 \
  "$HOME/.config/rofi/rofi_bg.jpg"

# 3. APLICAR FONDO DE PANTALLA
swww img "$WALLPAPER_PATH" --transition-type wave --transition-fps 60 --transition-duration 2 &

# 4. RECARGAR APLICACIONES
swaync-client -rs
quickshell &
disown

killall -SIGUSR1 kitty || true

echo "==> Theme update complete!"
