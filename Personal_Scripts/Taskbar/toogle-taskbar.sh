#!/bin/bash

if $(pgrep -f "/Taskbar/config" > /dev/null); then
    pkill -f "/Taskbar/config"
else
    waybar -c ~/.config/waybar/Taskbar/config -s ~/.config/waybar/Taskbar/style.css &
fi
