#!/bin/bash

# --- Configuración del Visualizador ---
bar=" ▂▃▄▅▆▇█"
dict="s/;//g"
bar_length=${#bar}

# Crear diccionario para sed (reemplaza números por barritas)
for ((i = 0; i < bar_length; i++)); do
  dict+=";s/$i/${bar:$i:1}/g"
done

# Configuración de Cava
config_file="/tmp/bar_cava_config"
cat >"$config_file" <<EOF
[general]
framerate = 60
bars = 10 
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Matar instancias previas
pkill -f "cava -p $config_file"

# --- Lógica de Audífonos + Pipeline ---

# Inicializamos variables
icon=" " # Icono por defecto (Altavoces)
counter=0
check_interval=60 # Revisar cada 120 frames (aprox 2 segundos a 60fps)

# 1. Ejecutamos Cava
# 2. Pasamos por sed para convertir números a gráficos
# 3. Leemos línea por línea para añadir el icono sin saturar la CPU
cava -p "$config_file" | sed -u "$dict" | while read -r line; do

  # Incrementamos contador
  ((counter++))

  # Solo revisamos hardware si el contador llega al límite
  if [ $counter -ge $check_interval ]; then
    if pactl list sinks | grep "Active Port" | grep -q "Headphones"; then
      icon=" " # Icono Audífonos
    else
      icon=" " # Icono Altavoces
    fi
    counter=0 # Reiniciar contador
  fi

  # Imprimimos: [ICONO] [VISUALIZADOR]
  echo "$icon $line"
done
