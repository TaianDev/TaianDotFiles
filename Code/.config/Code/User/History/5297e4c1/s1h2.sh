#!/bin/bash
PATH_WIDGET="$HOME/.config/quickshell/Translate/translate.qml"
BUFFER_FILE="/tmp/translate_buffer_input.txt"

if pgrep -f quickshell.*translate.qml > /dev/null; then
    pkill -f "quickshell.*translate.qml"
else
    SELECT_TEXT=$(wl-paste -p)
    echo "$q" > "$BUFFER_FILE"
    quickshell -p "$PATH_WIDGET" &
fi

