subcommand::clone::description() {
    echo Clone repositories
}

subcommand::clone::options () {
    echo "-fyi"
}

subcommand::clone() {
    util::ensure-repo-list
    _log "Cloning" "${LIST_OF_REPOS[*]}"
    for repo in "${LIST_OF_REPOS[@]}";do
        _clone_repo "$repo"
    done
}

_clone_repo() {
    repo=$1
    local repo_url="$DOTFILES_REPO_PREFIX${repo}$DOTFILES_REPO_SUFFIX"
    _log "Clone" "'$repo'"
    cd "$DOTFILES_REPODIR"

    local cloned=false
    local should_pull=false

    # Try to clone
    if [[ ! -e $repo ]];then
        git clone --depth 5 "$repo_url"
        if [[ ! -e $repo ]];then
            _error "Could not pull $repo_url"
            return 1
        fi
        cloned=true
    else
        # If already exists, check whether to pull
        if [[ $DOTFILES_OPT_FORCE == true || $DOTFILES_OPT_NOASK == true ]];then
            should_pull=true
        elif [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
            _ask_yes_no "Force Pull?" && should_pull=true
        fi
        if [[ $should_pull != true ]];then
            _warn "Repository '$repo' already exists"
        fi
    fi

    if [[ $should_pull == true ]];then
        _log "Pulling" "Repo exists, pulling"
        cd "$repo"
        if ! git pull ;then 
            _error "on 'git pull' of $repo"
            if [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
                _ask_yes_no "Open shell to resolve conflicts?" "yes" && $SHELL
            fi
        fi
    fi

    cd "$DOTFILEDIR"
}

