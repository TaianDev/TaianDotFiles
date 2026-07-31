#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "No wallpaper path provided. Won't update pywal and walcord colors."
  exit 1
fi

WALLPAPER_PATH="$1"

# 1. ACTUALIZAR ESTADO
#ln -sf "$WALLPAPER_PATH" "$HOME/.config/hypr/current_wall"

# 2. GENERACIÓN DE RECURSOS (bloqueante; mismo orden que pywal_global_update.sh)
wal -qste -i "$WALLPAPER_PATH"
matugen image "$WALLPAPER_PATH" --source-color-index 0

# 3. APLICAR FONDO DE PANTALLA
awww img "$WALLPAPER_PATH" --transition-type wave --transition-fps 60 --transition-duration 2 &

# 4. RECARGAR APLICACIONES (Theme.qml lo recoge ThemeLoader; no relanzar quickshell)
#swaync-client -rs 2>/dev/null || true

killall -SIGUSR1 kitty 2>/dev/null || true
