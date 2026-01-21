#!/bin/bash

# 1. Obtener la dirección de la ventana activa
ADDR=$(hyprctl activewindow -j | jq -r .address)

# 2. Propiedades visuales (Usando la sintaxis nueva para evitar el error DEPRECATED)
# Nota: "lock" asegura que Hyprland no restaure los bordes al mover la ventana.
hyprctl dispatch setprop address:$ADDR rounding 0 
hyprctl dispatch setprop address:$ADDR bordersize 0 
hyprctl dispatch setprop address:$ADDR noshadow 1

# 3. Hacer la ventana flotante
hyprctl dispatch setfloating address:$ADDR

# 4. DIMENSIONES CORRECTAS
# Ancho: 1366 (Todo el ancho)
# Alto: 726 (768 de pantalla - 42 de barra)
hyprctl dispatch resizeactive exact 1366 726

# 5. POSICIONAMIENTO EXACTO (La clave)
# En lugar de centrar, la movemos a la coordenada X:0 Y:42
hyprctl dispatch moveactive exact 0 42
