#!/bin/bash

dotfiledir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
repodir=$dotfiledir/repo
cd $dotfiledir

if [[ ! -e $repodir ]];then
    mkdir $repodir;
fi

setup_repo() {
    repo=$1
    echo "set up $repo"
    cd $repodir
    if [[ -e $repo ]];then
        echo "Repository $repo already exists, skipping";
    else
        git clone https://github.com/kba/${repo}.git
        cd $repo
        bash setup.sh
    fi
    cd $dotfiledir
}

setup_repo zsh-config
setup_repo vim-config
setup_repo home-bin
