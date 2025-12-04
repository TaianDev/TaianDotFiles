#!/bin/bash

# Script para controlar Spotify y obtener información
# Requiere playerctl instalado

PLAYER="spotify"

get_status() {
    playerctl --player=$PLAYER status 2>/dev/null || echo "Stopped"
}

get_title() {
    title=$(playerctl --player=$PLAYER metadata title 2>/dev/null)
    if [ -z "$title" ]; then
        echo "No song playing"
    else
        echo "$title"
    fi
}

get_artist() {
    artist=$(playerctl --player=$PLAYER metadata artist 2>/dev/null)
    if [ -z "$artist" ]; then
        echo "Unknown Artist"
    else
        echo "$artist"
    fi
}

get_position() {
    position=$(playerctl --player=$PLAYER position 2>/dev/null)
    if [ -z "$position" ]; then
        echo "0"
    else
        # Convertir a entero sin porcentaje ni decimales
        echo "$position" | cut -d'.' -f1
    fi
}



get_duration() {
    duration=$(playerctl --player=$PLAYER metadata mpris:length 2>/dev/null)
    if [ -z "$duration" ]; then
        echo "0"
    else
        # Convert microseconds to seconds
        echo $((duration / 1000000))
    fi
}

get_progress() {
    position=$(get_position)
    duration=$(get_duration)

    if [ "$duration" -eq 0 ]; then
        echo "0"
    else
        progress=$(echo "scale=2; $position * 100 / $duration" | bc 2>/dev/null)
        if [ -z "$progress" ]; then
            echo "0"
        else
            # Redondear el porcentaje
            printf "%.0f" "$progress" 2>/dev/null
        fi
    fi
}

get_artwork() {
    # Crear directorio para artwork si no existe
    artwork_dir="$HOME/.cache/eww/spotify"
    mkdir -p "$artwork_dir"
    
    artwork_url=$(playerctl --player=$PLAYER metadata mpris:artUrl 2>/dev/null)
    
    if [ -n "$artwork_url" ]; then
        # Extraer nombre de archivo del URL
        filename=$(basename "$artwork_url" | cut -d'?' -f1)
        if [ -z "$filename" ] || [ "$filename" = "basename" ]; then
            filename="current_artwork.jpg"
        fi
        
        artwork_path="$artwork_dir/$filename"
        
        # Descargar artwork si no existe o es muy antiguo (más de 5 minutos)
        if [ ! -f "$artwork_path" ] || [ $(($(date +%s) - $(stat -c %Y "$artwork_path" 2>/dev/null || echo 0))) -gt 300 ]; then
            curl -s "$artwork_url" -o "$artwork_path" 2>/dev/null
        fi
        
        if [ -f "$artwork_path" ]; then
            echo "$artwork_path"
        else
            echo "$artwork_dir/default.png"
        fi
    else
        echo "$artwork_dir/default.png"
    fi
}

create_default_artwork() {
    artwork_dir="$HOME/.cache/eww/spotify"
    mkdir -p "$artwork_dir"
    
    # Crear una imagen por defecto simple si no existe
    if [ ! -f "$artwork_dir/default.png" ]; then
        # Crear un PNG simple de 80x80 con color gris usando ImageMagick si está disponible
        if command -v convert >/dev/null 2>&1; then
            convert -size 80x80 xc:'#333333' "$artwork_dir/default.png" 2>/dev/null
        else
            # Si no hay ImageMagick, crear un archivo vacío que eww manejará
            touch "$artwork_dir/default.png"
        fi
    fi
}

toggle_playback() {
    playerctl --player=$PLAYER play-pause 2>/dev/null
}

next_track() {
    playerctl --player=$PLAYER next 2>/dev/null
}

previous_track() {
    playerctl --player=$PLAYER previous 2>/dev/null
}

# Crear artwork por defecto al inicio
create_default_artwork

case "$1" in
    "status")
        get_status
        ;;
    "title")
        get_title
        ;;
    "artist")
        get_artist
        ;;
    "position")
        get_position
        ;;
    "duration")
        get_duration
        ;;
    "progress")
        get_progress
        ;;
    "artwork")
        get_artwork
        ;;
    "toggle")
        toggle_playback
        ;;
    "next")
        next_track
        ;;
    "previous")
        previous_track
        ;;
    *)
        echo "Usage: $0 {status|title|artist|position|duration|progress|artwork|toggle|next|previous}"
        exit 1
        ;;
esac
