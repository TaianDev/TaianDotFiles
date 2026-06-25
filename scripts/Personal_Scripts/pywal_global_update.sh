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
wal -qste -i "$WALLPAPER_PATH"
matugen image "$WALLPAPER_PATH" --source-color-index 0

#jq -s '.[0] * .[1]' \
#  ~/.config/Code/User/settings.json \
#  /tmp/vscode-matugen.json \
#  >/tmp/vscode-merged.json &&
#mv /tmp/vscode-merged.json ~/.config/Code/User/settings.json

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
pkill hyprwave || true
hyprwave &
disown

killall -SIGUSR1 kitty || true

echo "==> Theme update complete!"
