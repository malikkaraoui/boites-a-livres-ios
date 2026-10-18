#!/bin/zsh
# usage: planche.sh <sortie.png> <titre> <fichiers...>
O=$1; T=$2; shift 2
montage "$@" -resize 300x -label '%t' -set label '%t' -font /System/Library/Fonts/Supplemental/Arial.ttf -pointsize 16 -geometry +6+6 -tile ${#@}x1 -title "$T" "$O"
