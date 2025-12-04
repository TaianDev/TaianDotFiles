#!/bin/bash

# Este script recupera la carátula de la canción actualmente reproducida por Tidal o Spotify.
# Esta diseñado para trabajar con Eww, de manera que optimiza
# el uso de red y de disco.

WIDGET_DIR=$(dirname "$0")
DEFAULT_COVER="$WIDGET_DIR/assets/DEFAULTImage.jpeg"
CACHE_DIR="$HOME/.cache/eww/music-widget"
mkdir -p "$CACHE_DIR"

# Funcion para mostrar la carátula por defecto
show_default_cover() {
    echo "$DEFAULT_COVER"
    exit 0
}

# Obtiene la URL de la portada de la canción que se esta reproduciendo, y si ocurre un error
# muestra la carátula por defecto
COVER_URL=$(playerctl metadata mpris:artUrl -p spotify,tidal-hifi 2>/dev/null)
if [[ -z "$COVER_URL" ]]; then
    show_default_cover
fi

# Si la carátula esta almacenada de manera local, entonces se toma esa ruta.
if [[ "$COVER_URL" == file://* ]]; then
    # URL-decode the path to handle special characters like spaces
    LOCAL_PATH=$(printf '%b' "${COVER_URL#file://}")
    if [[ -f "$LOCAL_PATH" ]]; then
        echo "$LOCAL_PATH"
        exit 0
    else
        show_default_cover
    fi
fi

# Si la carátula no esta almacenada localmente, se procede a descargar la imagen y obtener su hash
URL_HASH=$(echo -n "$COVER_URL" | md5sum | awk '{print $1}')
EXTENSION="${COVER_URL##*.}"
if [[ "$EXTENSION" == "$COVER_URL" ]] || [[ ${#EXTENSION} -gt 5 ]]; then
    EXTENSION="jpg"
fi
CACHED_COVER="$CACHE_DIR/$URL_HASH.$EXTENSION"

# Si la carátula ya esta guardada en el disco, entonces no se descarga nada. Si no lo esta, entonces se descarga 
if [ ! -f "$CACHED_COVER" ]; then
    curl -s -L --max-time 5 "$COVER_URL" -o "$CACHED_COVER"
    if [[ $? -ne 0 ]] || [[ ! -s "$CACHED_COVER" ]]; then
        rm -f "$CACHED_COVER"
        show_default_cover
    fi
fi

# Esta es una sanitización para asegurar que el formato de la imagen sea correcto
if file "$CACHED_COVER" | grep -qE 'image|jpeg|png|jpg|gif'; then
    echo "$CACHED_COVER"
else
    rm -f "$CACHED_COVER"
    show_default_cover
fi

exit 0
