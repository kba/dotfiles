subcommand::status::description () {
    echo "Repo status"
}
subcommand::status::options () {
    echo "-Fr"
}

subcommand::status() {
    util::ensure-repo-list
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Status'ing repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd "$repo"
        _logn "git status" "$repo"
        [[ $DOTFILES_OPT_FETCH == true ]] && git fetch >/dev/null 2>&1
        status="$(git status -s|_indent)"
        if [[ -z "$status" ]];then
            echo -e "\r`C 2`unchanged "
        else
            echo -e "\r`C 1`changed    `C`"
            echo "$status"
        fi
    done
}

