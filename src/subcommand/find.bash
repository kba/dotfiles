#{{{ _find_dotfiles
_find_dotfiles() {
    # Only files and symlinks
    # Only in hidden subdirectories named like an environment variable
    # find -L repo -type f,l |grep '\.[A-Z_]\+/'
    find -H "$DOTFILEDIR/repo" -mindepth 3|grep '/\.[A-Z_]\+' 
}
#}}}
#{{{ _find_all
_find_all() {
    find -H "$DOTFILEDIR/repo" -mindepth 3 -type f,l | grep -v '\.git\|bundle\|cache'
}
#}}}
subcommand::find::description() {
    echo "Find all dotfiles"
}
subcommand::find() {
echo "'$@'"
    func="_find_dotfiles"
    echo "$DOTFILES_OPT_ALL"
    if [[ $DOTFILES_OPT_ALL = true ]];then
        _find_all
    else
        _find_dotfiles
    fi

}
