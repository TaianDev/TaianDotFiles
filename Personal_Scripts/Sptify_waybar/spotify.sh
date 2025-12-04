#!/bin/bash

show_default() {
    echo '{"text":"󰓇\u00A0\u00A0  Nothing sound","class":"spotify"}'
}

# Mostrar valor por defecto si Spotify no está abierto
if ! pgrep -x spotify >/dev/null; then
    show_default
fi

# Escuchar cambios en estado y metadatos de Spotify
playerctl --player=spotify --follow metadata --format '{"text":"󰓇  {{title}} - {{artist}}","class":"spotify"}' 2>/dev/null | while read -r line; do
    status=$(playerctl --player=spotify status 2>/dev/null)

    if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
        echo "$line"
    else
        show_default
    fi
done
