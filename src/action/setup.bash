action_setup() {
    _log "Setting up" "${LIST_OF_REPOS[*]}"
    for repo in "${LIST_OF_REPOS[@]}";do
        _setup_repo "$repo"
    done
}

