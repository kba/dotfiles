#!/bin/bash
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

guake&
fbxkb&
bash $DIR/synaptics.sh&
conky -c $DIR/conky-right&
xbindkeys&
redshift&
clipit&
compiz --replace&
