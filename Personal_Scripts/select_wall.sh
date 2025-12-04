#!/bin/bash

DIR=/home/taian/Imágenes/Fondos

cd $DIR || exit 1

# Abre rofi
WALL=$(for a in *.jpg *.png; do echo -en "$a\0icon\x1f$a\n" ; done | rofi -dmenu -p "" -theme "~/.config/rofi/test-previews.rasi")

#Cambiar con sww
/home/taian/Personal_Scripts/pywal_global_update.sh "$WALL"
