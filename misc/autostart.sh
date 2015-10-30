#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

bash $DIR/synaptics.sh&
setxkbmap -option grp:alt_space_toggle us,de

    # volbrid
for cmd in $(echo "
    nm-applet
    fbxkb
    guake
    redshift-gtk
    clipit
    conky
    xbindkeys
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
sleep 10 && compiz --replace&
