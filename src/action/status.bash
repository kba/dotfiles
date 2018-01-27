action_status() {
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Status'ing repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd "$repo"
        _log "git status" "$repo"
        [[ $DOTFILES_OPT_FETCH == true ]] && git fetch >/dev/null 2>&1
        git status -s|_indent
    done
}

