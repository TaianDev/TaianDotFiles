#!/bin/bash

FILE="/home/taian/Personal_Scripts/EWW_widget_sp/det.txt"

if [ ! -f "$FILE" ]; then
    echo "open" > "$FILE"
    eww close all
    eww open spotify-player
else
    state=$(cat "$FILE")
    if [ "$state" = "open" ]; then
        eww close spotify-player
        echo "close" > "$FILE"
    else
	eww close calendar-window
        echo "close" > "/home/taian/Personal_Scripts/EWW_calendar/det.txt"
        eww open spotify-player
        echo "open" > "$FILE"
    fi
fi

