subcommand::setup::description() {
    echo Setup repositories
}

subcommand::setup::options () {
    echo "-fyi"
}

subcommand::setup() {
    _log "Setting up" "${LIST_OF_REPOS[*]}"
    for repo in "${LIST_OF_REPOS[@]}";do
        _setup_repo "$repo"
    done
}

_setup_repo() {
    repo=$1
    local repo_url="$DOTFILES_REPO_PREFIX${repo}$DOTFILES_REPO_SUFFIX"
    _log "SETUP" "Setting up '$repo'"
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
        _warn "Repository '$repo' already exists"
        if [[ $DOTFILES_OPT_FORCE == true || $DOTFILES_OPT_NOASK == true ]];then
            should_pull=true
        elif [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
            _ask_yes_no "Force Pull?" && should_pull=true
        fi
    fi

    cd "$repo"

    if [[ $should_pull == true ]];then
        if ! git pull ;then 
            _error "on 'git pull' of $repo"
            if [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
                _ask_yes_no "Open shell to resolve conflicts?" "yes" && $SHELL
            fi
        fi
    fi

    local do_setup=false

    if [[ $cloned == true || $DOTFILES_OPT_FORCE == true ]];then
        do_setup=true
    elif [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
        _ask_yes_no "Force Setup?" "no" && do_setup=true
    fi

    if [[ "$do_setup" == true ]];then
        for confdir in ".HOME" ".XDG_CONFIG_HOME";do
            targetdir=~
            if [[ $confdir == ".XDG_CONFIG_HOME" ]];then
                targetdir=~/.config
            fi
            backup_tstamp="$DOTFILES_BACKUPDIR/$now/$confdir"
            if [ -e $confdir ];then
                # shellcheck disable=SC2044
                for dotfile in $(find "$confdir" -mindepth 1 -name '*' -exec basename {} \;);do
                    backup="$backup_tstamp/$dotfile"
                    mkdir -p "$backup_tstamp"
                    _log "BACKUP" "$(C 1)$targetdir/$dotfile$(C) -> $backup"
                    mv -vf "$targetdir/$dotfile" "$backup"
                    _log "SYMLINK" "$repo/$confdir/$dotfile -> $(C 2)$targetdir/$dotfile$(C)"
                    ln -fs "$(readlink -f "$confdir/$dotfile")" "$targetdir/$dotfile"
                done
            else
                _warn "No $confdir for $repo"
            fi
        done
        for initsh in "init.sh" "setup.sh" "install.sh";do
            if [ -e $initsh ];then
                source $initsh
            fi
        done
    fi

    cd "$DOTFILEDIR"
}

