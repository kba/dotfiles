subcommand::pull::description() {
    echo "Pull all repos"
}

subcommand::pull::options () {
    echo "-r"
}

subcommand::pull() {
    util::ensure-repo-list
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Pulling repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd $repo
        _log "git pull" "$repo"
        git pull -q --stat origin master 2>&1|_indent
    done
}
