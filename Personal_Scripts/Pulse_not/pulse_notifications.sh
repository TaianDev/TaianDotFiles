#!/bin/bash

# Ejecuta swaync toggle
swaync-client -t

# Imprime el JSON para Waybar con clase "pulse"
echo '{"text":"󰣇","class":"pulse"}'

# Espera que termine la animación y vuelve a normal
sleep 0.6
echo '{"text":"󰣇"}'
