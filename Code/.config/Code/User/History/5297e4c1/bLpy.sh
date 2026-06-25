#!/bin/bash
PATH_WIDGET="$HOME/.config/quickshell/Translate/translate.qml"

if [ pgrep -f quickshell.*translate.qml > /dev/null ]; then
    pkill -f quickshell.*translate.qml
else
    SELECT_TEXT = $(wl-paste -p)
    echo "$SELECT_TEXT" > /tmp/translate_buffer_input.txt
    quickshell -p "$PATH_WIDGET" &
fi

