#!/bin/bash

# Carpeta de fondos
WALL_DIR="$HOME/Wallpappers/Static_wall/WALLS"

# Lista de fondos (ordena por nombre para que sea consistente)
wallpapers=(
    "$WALL_DIR/wall1.jpg"
    "$WALL_DIR/wall2.jpg"
    "$WALL_DIR/wall3.jpg"
    "$WALL_DIR/wall4.jpg"
    "$WALL_DIR/wall5.jpg"
    "$WALL_DIR/wall6.jpg"
)

# Transiciones específicas por fondo (en el mismo orden)
transitions=(
    "center"
    "center"
    "center"
    "center"
    "center"
    "center"
)

# Archivo que guarda el índice actual
INDEX_FILE="/home/taian/Personal_Scripts/Switch_wall/current.txt"

# Leer índice actual, o iniciar en 0 si no existe
if [[ -f "$INDEX_FILE" ]]; then
    index=$(<"$INDEX_FILE")
else
    index=0
fi

# Asegurar que esté dentro del rango
index=$((index % 6))

# Obtener fondo y transición actual
wall="${wallpapers[$index]}"
transition="${transitions[$index]}"

# Iniciar swww si no está en ejecución
if ! pgrep -x "swww-daemon" > /dev/null; then
    swww init
    sleep 1
fi

# Aplicar el fondo con su transición
swww img "$wall" --transition-type "$transition" --transition-fps 60 --transition-duration 1

# Aplicar la paleta con wal
wal -i "$wall" > /dev/null 2>&1

# Guardar nuevo índice (siguiente fondo para la próxima vez)
echo $(( (index + 1) % 6 )) > "$INDEX_FILE"

#PARA EL SWITCH
sleep 0.2
killall -USR1 zsh 2>/dev/null || true
