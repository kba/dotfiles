subcommand::push::description() {
    echo "Push all repos"
}
subcommand::push() {
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Pulling repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd $repo
        _log "git push" "Pushing $repo"
        if git diff-index --quiet --cached HEAD --;then
            git push 2>&1|_indent
        elif [[ "$DOTFILES_OPT_INTERACTIVE" == true ]];then
            git add .
            git commit -v && git push|_indent
        else
            _warn "Untracked files not add/commit/push unless --interactive"
        fi
    done
}
