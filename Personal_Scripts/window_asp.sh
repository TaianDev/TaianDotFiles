#!/bin/bash

hyprctl setprop address:$(hyprctl activewindow -j | jq -r .address) rounding 0; \
hyprctl setprop address:$(hyprctl activewindow -j | jq -r .address) bordersize 0;
hyprctl setprop address:$(hyprctl activewindow -j | jq -r .address) noshadow 1;
hyprctl dispatch togglefloating address:$(hyprctl activewindow -j | jq -r .address)
hyprctl dispatch resizeactive exact 1366 728
hyprctl dispatch centerwindow
