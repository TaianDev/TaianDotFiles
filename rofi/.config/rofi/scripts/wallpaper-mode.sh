#!/bin/bash

# Directorio de tus fondos
DIR="$HOME/Imágenes/Fondos"

# Si no hay argumentos, Rofi está pidiendo la lista
if [ -z "$@" ]; then
  cd "$DIR" || exit
  # Bucle para listar archivos
  for a in *.jpg *.png *.jpeg; do
    # Si no existen archivos, evitar imprimir "*.jpg"
    [ -e "$a" ] || continue

    # Sintaxis mágica de Rofi: Nombre \0icon\x1f Ruta_Icono
    # Esto pone la propia imagen como icono en la lista
    echo -en "$a\0icon\x1f$DIR/$a\n"
  done
else
  # Si hay argumento, es que el usuario seleccionó una imagen ($@ es el nombre)
  SELECCION="$DIR/$@"

  # Ejecuta tu script de actualización (sin abrir terminal ni bloquear)
  /home/taian/Personal_Scripts/pywal_global_update.sh "$SELECCION" >/dev/null 2>&1 &
fi
