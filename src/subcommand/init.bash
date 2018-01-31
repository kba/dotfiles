subcommand::init::description () {
    echo "Run the init script in each repo"
}

subcommand::init () {
    util::ensure-repo-list
    _log "Initializing" "${LIST_OF_REPOS[*]}"
    cd "$DOTFILES_REPODIR"

    for repo in "${LIST_OF_REPOS[@]}";do
        pushd $repo

        util::backup $now $PWD
        util::symlink $PWD

        for initsh in "init.sh" "setup.sh" "install.sh";do
            if [ -e $initsh ];then
                source $initsh
            fi
        done

        popd
    done
    local do_setup=false
}
