#!/bin/bash

show_default() {
    echo '{"text":"󰓇\u00A0\u00A0  Nothing sound","class":"spotify"}'
}

while true; do
    if pgrep -x spotify >/dev/null; then
        status=$(playerctl --player=spotify status 2>/dev/null)
        if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
            title=$(playerctl --player=spotify metadata title 2>/dev/null)
            artist=$(playerctl --player=spotify metadata artist 2>/dev/null)
            echo "{\"text\":\"󰓇  $title - $artist\",\"class\":\"spotify\"}"
        else
            show_default
        fi
    else
        show_default
    fi
    sleep 1
done
