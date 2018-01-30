subcommand::usage::description () {
    echo "Show usage"
}
subcommand::usage() {
    echo "`C 10`$0 `C` [options] <action> [repo...]"
    echo
    echo "  `C 3`Options:`C`"
    echo "    `C 12`-f --force`C`       Setup symlinks for the repo no matter what"
    echo "    `C 12`-a --all`C`         Run command on all existing repos"
    echo "    `C 12`-i --interactive`C` Ask for confirmation"
    echo "    `C 12`-y --noask`C`       Assume defaults (i.e. don't ask but assume yes)"
    echo "    `C 12`-F --fetch`C`       Fetch changes"
    echo "    `C 12`-r --recursive`C`   Check for git repos recursively"
    echo "    `C 12`-d --debug`C`       Show Debug output"
    echo "  `C 3`Actions:`C`"
    for cmd in $(declare -F |sed 's/^declare -f //'|grep '^subcommand::[^:]*$');do
        echo "`C 12`    ${cmd#*::}`C`	$($cmd::description)"
    done
    echo
    if [[ $DOTFILES_OPT_DEBUG == true ]];then 
        echo "  `C 3`Repos:`C` [Default: all of them]"
        for repo in "${LIST_OF_REPOS[@]}";do
            echo -e "    `C 12`$repo`C`\t     $DOTFILES_REPO_PREFIX$repo$DOTFILES_REPO_SUFFIX"
        done;
        echo -e "\n  `C 3`Variables:`C`"
        _debug|_indent
    fi
    exit
}

