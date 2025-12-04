#!/bin/bash

FILE="/home/taian/.cache/battery_info"

#Verifica si el archivo existe, y si no, lo crea
if [[ -z "$(find ~/.cache/ -type f -name 'battery_info')" ]]; then
 echo "No existe el archivo, \"battery_info\", se creara en la ruta $FILE" 
 touch ~/.cache/battery_info
fi

#Actualiza la información del archivo

STATE="$(cat /sys/class/power_supply/BAT0/status)"
PERCENTAGE="$(cat /sys/class/power_supply/BAT0/capacity)" 

if [[ "$(echo $STATE)" == "Full" ]]; then
  echo "⚡ Batería cargada ($PERCENTAGE)" > $FILE
elif [[ "$(echo $STATE)" == "Charging" ]]; then
  echo "🔌 Cargando ($PERCENTAGE%)" > $FILE
elif [[ "$(echo $STATE)" == "Discharging" ]]; then
  echo "🔋 Descargando ($PERCENTAGE%)" > $FILE
fi  

echo "$(cat $FILE)"
