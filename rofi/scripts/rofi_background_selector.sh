#!/bin/bash

CACHE_ROOT=~/wallpapers/cached-imgs
WALLPAPER_ROOT=~/wallpapers

mapfile -t originPath < <(find ${WALLPAPER_ROOT} -maxdepth 1 -type f)
mapfile -t cachedPath < <(find ${CACHE_ROOT} -maxdepth 1 -type f)
declare -A bgresult
declare -A cachedresult

bgnames=()

function cacheImg {
    resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 $1)
    width_=$(echo "${resolution}" | awk -F',' '{print $1}')
    height_=$(echo "${resolution}" | awk -F',' '{print $2}')
    if [ "${width_}" -lt "${height_}" ]
    then
        ffmpeg -i $1 -loglevel quiet -vf  "scale=1024:-1, crop=1024:1024:0:(iw-1024)/2" $2
    else
        ffmpeg -i $1 -loglevel quiet -vf  "scale=-1:1024, crop=1024:1024:(iw-1024)/2:0" $2
    fi
    echo $2
}

function getFileName {
    echo "$1" | xargs basename | awk -F'.' '{print $1}'
}

for pathIDX in "${!originPath[@]}"; do
    filename=$(getFileName "${originPath[$pathIDX]}")
    bgresult["${filename}"]="${originPath[$pathIDX]}"
    bgnames[$pathIDX]+="${filename}"
done


for pathIDX in "${!cachedPath[@]}"; do
    filename=$(getFileName "${cachedPath[$pathIDX]}")
    cachedresult["${filename}"]="${cachedPath[$pathIDX]}"
done


for fName in "${bgnames[@]}"; do
    if [[ -v cachedresult[$fName] ]] 
    then
        :
    else
        cachedresult[$fName]=$(cacheImg "${bgresult[$fName]}" "${CACHE_ROOT}/${fName}.png")
    fi
done

strrr=""
for fName in "${bgnames[@]}"; do
    strrr+="$(echo -n "${fName}\0icon\x1f${cachedresult[$fName]}\n")"
done

selected=$(echo -en "${strrr}" | rofi -dmenu -show-icons -no-layers -p "search" -config $1 -theme ~/.config/rofi/wallcfg.rasi)
awww img "${bgresult[$selected]}" --transition-type wipe --transition-fps 60
