#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

for cmd in $(echo "
    nm-applet
    devilspie2
    fbxkb
    guake
    xbindkeys
    redshift-gtk
    clipit
    conky
    ");do
    if which $cmd >/dev/null 2>&1; then
        echo pkill -f "$cmd"
        pkill -f "$cmd"
        echo sh -c "$cmd"
        sh -c "$cmd"&
    else
        echo "Not installed: $cmd"
    fi
done
bash $DIR/synaptics.sh&
setxkbmap -option grp:alt_space_toggle us,de
compiz --replace&
