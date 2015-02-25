#!/bin/bash

base=$(readlink -f $PWD)
for repo in repo/*;do
    echo $repo
    cd $base/$repo
    git pull
done

