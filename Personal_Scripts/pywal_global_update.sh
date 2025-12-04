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
	wal -q -i "$WALLPAPER_PATH"
	
#	echo "Updating Vesktop walcord theme..."
#	walcord -i $WALLPAPER_PATH -t ~/.config/vesktop/themes/midnight-vesktop.template.css -o ~/.config/vesktop/themes/midnight-vesktop.theme.css 
fi

#echo "Reloading Wayland notification daemon..."
swaync-client -rs
eww reload -c /home/taian/.config/eww/Taian_Widgets
echo "==> Theme update complete!"
