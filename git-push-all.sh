#!/bin/bash

base=$(readlink -f $PWD)
for repo in repo/*;do
    echo $repo
    cd $base/$repo
    git add -A .
    git commit -v
    git push
done

