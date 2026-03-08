#!/usr/bin/env bash

# A script to apply a new pywal theme to all relevant applications.
# This script is intended to be called by another program (like waypaper)
# that provides the path to the new wallpaper as the first argument.

set -e

if [ -z "$1" ]; then
  echo "No wallpaper path provided. Won't update pywal and walcord colors."
else
  WALLPAPER_PATH="$1"
  echo "Setting new theme from: $WALLPAPER_PATH"
  swww img "$WALLPAPER_PATH" --transition-type wave --transition-fps 60 --transition-duration 2
  wal -qst -i "$WALLPAPER_PATH"
  matugen image "$WALLPAPER_PATH"
  swaync-client -rs
  ln -sf "$WALLPAPER_PATH" "$HOME/.config/hypr/current_wall"
  pkill hyprwave
  hyprwave & disown
  #  ln -sf "$WALLPAPER_PATH" "$HOME/.config/rofi/current_wall"
  magick "$WALLPAPER_PATH" \
    -resize 1280x720^ \
    -gravity center \
    -extent 1280x720 \
    -strip \
    -sampling-factor 4:2:0 \
    -quality 20 \
    /home/taian/.config/rofi/rofi_bg.jpg
  killall -SIGUSR1 kitty
fi

#echo "Reloading Wayland notification daemon..."
echo "==> Theme update complete!"
