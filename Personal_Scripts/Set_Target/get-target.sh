#!/bin/bash
TARGET_FILE="/home/taian/Personal_Scripts/Set_Target/target.txt"

if [[ -f "$TARGET_FILE" && -s "$TARGET_FILE" ]]; then
    echo "󰣉   $(cat "$TARGET_FILE")"
else
    echo "󰣉   No-target"
fi
