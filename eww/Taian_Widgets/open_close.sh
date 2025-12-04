#!/bin/bash

if [[ -z $(hyprctl layers | grep audio) ]]; then
 eww -c ~/.config/eww/Taian_Widgets open audio
else
 eww -c ~/.config/eww/Taian_Widgets close audio
fi
