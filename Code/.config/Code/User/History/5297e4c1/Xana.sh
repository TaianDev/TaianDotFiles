#!/bin/bash
PATH_WIDGET="$HOME/.config/quickshell/Translate/translate.qml"
BUFFER_FILE="/tmp/translate_buffer_input.txt"

if ! wl-paste -p >/dev/null 2>&1; then
    echo "El portapapeles primario está vacío. Saliendo..."
    exit 1
fi

if pgrep -f quickshell.*translate.qml > /dev/null; then
    pkill -f "quickshell.*translate.qml"
else
    SELECT_TEXT=$(wl-paste -p)
    echo "$SELECT_TEXT" > "$BUFFER_FILE"
    quickshell -p "$PATH_WIDGET" &
fi

