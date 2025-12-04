#!/bin/bash

# █▄▄ █▄█   #  ▀█▀ ▄▀█ █ ▄▀█ █▄░█ █▀ █▀▀ █▀▀
# █▄█ ░█░   #  ░█░ █▀█ █ █▀█ █░▀█ ▄█ ██▄ █▄▄

# GitHub profile: https://github.com/TaianDev

function get_title(){
 playerctl metadata --format '{{title}}' --follow -p spotify,tidal-hifi || echo "Unknow"
}

function get_artist(){
 playerctl metadata --format '{{artist}}' --follow -p spotify,tidal-hifi || echo "Non-recognized"
}

function get_album(){
 playerctl metadata --format '{{album}}' --follow -p spotify,tidal-hifi || echo "-"
}

function get_cover(){
/home/taian/.config/eww/Taian_Widgets/ewwW_scripts/get-cover.sh  
}

function get_len(){
playerctl metadata --format '{{duration(mpris:length)}}' -p spotify,tidal-hifi || echo "0:00"
}

function get_current(){
playerctl metadata --format '{{duration(position)}}' -p spotify,tidal-hifi || echo "0:00"
}
case "$1" in
  "title")
    get_title;;
  "artist")
    get_artist;;
  "album")
    get_album;;
  "cover")
    get_cover;;
  "len")
    get_len;;
  "current")
    get_current;;
  *)
    echo -e "Opciones disponibles:\n*title\n*artist\n*cover\n*len\n*current";;
esac

