subcommand::archive::description() {
    echo "Create an archive of current state"
}

subcommand::archive::options () {
    echo "-r"
}

subcommand::archive () {
    local dotignore=$(mktemp "/tmp/dotfiles-XXXXX.dotignore")
    local dotfiles_tar=$(mktemp "/tmp/dotfiles-XXXXX.tar.gz")
    local dotfiles_basename=${DOTFILEDIR##*/}
    echo > "$dotignore"
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    for repo in "${repos[@]}";do
        if [[ -e "$repo/.dotignore" ]];then
            sed -e '/^\s*$/ d' -e "s,^.*,$dotfiles_basename/repo/${repo##*/}/\\0," \
                < "$repo/.dotignore" \
                >> "$dotignore"
        fi
    done
    cd "$DOTFILEDIR/.."
    _log "git archive ignore" "$(_indent < "$dotignore")"
    _log "git archive" "Creating: $dotfiles_tar"
    tar cjf "$dotfiles_tar" -X "$dotignore" "$dotfiles_basename"
    _log "git archive" "Created"
    rm "$dotignore"
}

