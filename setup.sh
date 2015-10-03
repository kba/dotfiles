#!/bin/bash

source <(curl -s "https://raw.githubusercontent.com/kba/shcolor/master/shcolor.sh")

export SHBOOTRC_RUNNING=true
EDITOR=vim

#{{{ 
# Utility functions for drawing stuff
_textWidthWithoutEscapeCodes() {
    local message=$(echo $1|sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
    local padding=3
    [[ $2 ]] && padding=$2
    local messageLength=$(echo $message|wc -c)
    messageLength=$(echo "$messageLength + $padding"|bc)
    echo $messageLength
}
_colorecho() {
    echo -ne "$(C $2)$1"
}
boxFat() {
    color=$1
    char=$2
    message=$3
    width=$(_textWidthWithoutEscapeCodes "$message" 4)
    echo -ne $(C $color)
    for i in $(seq $width);do
        echo -ne $2
    done
    echo
    _colorecho "$char" "$color"
    _colorecho " $message "
    echo -ne $(C 0)
    _colorecho "$char" "$color"
    echo
    echo -ne $(C $color)
    for i in $(seq $width);do
        echo -ne $2
    done
    echo `C`
}
boxLeftChar() {
    color=$1
    chars=$2
    message=$3
    echo "`C $color`$chars`C` $message"
}
#}}}

dotfiledir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dotfiledir

export OPT_INTERACTIVE=false
export OPT_ASSUME_DEFAULT=false
export OPT_FORCE_SETUP=false

export REPO_PREFIX="https://github.com/kba/"
export REPO_SUFFIX=".git"

# The global action
export GLOBAL_ACTION="usage"

# The 
export ORIG_ARGS
export GLOBAL_ARGS=()
export ACTION_FUNC

BACKUP_LIST="$dotfiledir/.backup.list"
[[ ! -e $BACKUP_LIST ]] && touch $BACKUP_LIST;

repodir=$dotfiledir/repo
LIST_OF_REPOS=()
DEFAULT_REPOS=(
    zsh-config
    vim-config
    home-bin
    tmux-config
)

if [[ ! -e $repodir ]];then
    mkdir $repodir;
fi

#{{{
ask_yes_no() {
    default_to_yes=$2
    if [[ ! -z $default_to_yes && "$default_to_yes" == "yes" ]];then
        echo -n "`C 87 b`??`C` $1 <`C 1`Y`C`es/o> " >&2
        read yesno
        if [[ -z "$yesno" || "$yesno" == "yes" || "$yesno" == "y" ]];then
            echo "yes"
        fi
    else
        echo -n "`C 87 b`??`C` $1 <yes/`C 1`N`C`o> " >&2
        read yesno
        if [[ "$yesno" == "yes" || "$yesno" == "y" ]];then
            echo "yes"
        fi
    fi
}
export -f ask_yes_no
#}}}
#{{{
setup_repo() {
    repo=$1
    boxLeftChar 2 '>>>'
    boxLeftChar 2 '>>>' "Setting up '$repo'"
    boxLeftChar 2 '>>>'
    cd $repodir
    if [[ -e $repo ]];then
        boxLeftChar 1 '!!' "Repository '$repo' already exists";
        should_pull=false
        if [[ $OPT_ASSUME_DEFAULT == true ]];then
            should_pull=true
        elif [[ $OPT_INTERACTIVE == true && $(ask_yes_no "Force Pull?" "yes") = "yes" ]];then
            should_pull=true
        fi
        cd $repo
        if [[ $should_pull == true ]];then
            git pull
            if [[ "$?" -gt 0 ]];then
                boxLeftChar 1 '  !!' "Error on `C 2`git pull`C`"
                if [[ $OPT_INTERACTIVE == true && $(ask_yes_no "Open shell to resolve conflicts?") = "yes" ]];then
                    $SHELL
                fi
            fi
        fi
        if [[ $OPT_FORCE_SETUP = true || ($OPT_INTERACTIVE == true && $(ask_yes_no "Force Setup?" "no") == "yes") ]];then
            now=$(date +%s%N)
            if [ -e .home ];then
                for dotfile in $(find .home -mindepth 1 -name '.*' -exec basename {} \;);do
                    echo mv $HOME/$dotfile $HOME/$dotfile.$now
                    mv $HOME/$dotfile $HOME/$dotfile.$now
                    echo "$HOME/$dotfile.$now" >> $BACKUP_LIST
                    echo ln -s $(readlink -f .home/$dotfile) $HOME/$dotfile
                    ln -s $(readlink -f .home/$dotfile) $HOME/$dotfile
                done
            else
                echo "$(C 10)WARNING: No .home for $repo"
            fi
            if [ -e setup.sh ];then
                source setup.sh
            fi
        fi
    else
        git clone "$REPO_PREFIX${repo}$REPO_SUFFIX"
        setup_repo $repo
    fi
    cd $dotfiledir
}
#}}}

#{{{ 
function action_remove_backups() {
while read $backup;do
    [[ -e $backup && -L $backup ]] && rm -v $backup
done < $BACKUP_LIST
}
#}}}
#{{{
function debug() {
    echo -e "$(C 3)"
    echo "Action: $(C 5 b)$GLOBAL_ACTION $(C 3)"
    echo "Action Function: $ACTION_FUNC"
    echo "Global args: $GLOBAL_ARGS"
    echo "OPT_FORCE_SETUP: $OPT_FORCE_SETUP"
    echo "Action args: $ACTION_ARGS"
    echo -e "$(C)"
}
#}}}
#{{{ 
function action_usage() {
echo "$(C 10)$0 $(C 9) [-if] [--force-setup] <action> <repo>"
echo
echo "  $(C 3)Repos:$(C) [Default: all of them]"
for repo in ${LIST_OF_REPOS[@]};do
echo -e "    $(C 12)$repo$(C)\t$REPO_PREFIX$repo$REPO_SUFFIX"
done;
echo
echo "  $(C 3)Options:$(C 9)"
echo "    $(C 12)-i --interactive$(C 9) interactive"
echo "    $(C 12)-y --noask$(C 9)       assume defaults (i.e. don't ask)"
echo "    $(C 12)--force-setup$(C 9)    Setup symlinks for the repo no matter what"
echo
echo "  $(C 3)Actions:$(C 9)"
echo
echo "    $(C 12)help$(C 9)             This help screen "
echo "    $(C 12)remove-backups$(C 9)   Remove all timestamped backups"
echo "    $(C 12)setup-repo$(C 9)       Setup repositories"
echo "    $(C 12)push-all$(C 9)         Push all changes"
echo
debug
exit
}
#}}}
#{{{
function action_setup_repo() {
    boxFat 4 '#' "Setting up: `C 3 b` $(echo ${LIST_OF_REPOS[@]})"
    for repo in ${LIST_OF_REPOS[@]};do
        setup_repo $repo
    done
}
#}}}
#{{{
function action_push_all() {
    boxFat 4 "#" "Pushing repos: $(echo ${LIST_OF_REPOS[@]})"
    for repo in ${LIST_OF_REPOS[@]};do
        cd repo/$repo
        boxLeftChar 2 '>>>'
        boxLeftChar 2 '>>>' "Pushing $repo"
        boxLeftChar 2 '>>>'
        git add -A .
        git commit -v
        git push
        cd $dotfiledir
    done
}
#}}}
#{{{
function parse_commandline() {
    # {{{
    # {{{
    # set up GLOBAL_ARGS 
    while (( "$#" ));do
        case "$1" in
            -*)
                case "$1" in
                    "-i"|"--interactive")
                        OPT_INTERACTIVE=true
                        ;;
                    "--force-setup")
                        OPT_FORCE_SETUP=true
                        ;;
                    "-f"|"--noask")
                        OPT_ASSUME_DEFAULT=true
                        ;;
                esac
                GLOBAL_ARGS+=$1
                shift
                ;;
            # TODO GLOBAL_ACTION
            *)
            break
            ;;
        esac
    done
    debug
    # }}}
    # {{{
    # set up $GLOBAL_ACTION
    if [[ ! -z "$1" ]];then
        case "$1" in
            "setup-repo")
                GLOBAL_ACTION="setup-repo"
                ;;
            "help"|"usage")
                GLOBAL_ACTION="usage"
                ;;
            "push-all")
                GLOBAL_ACTION="push-all"
                ;;
            *)
                GLOBAL_ACTION="usage"
                ;;
        esac
    fi
    ACTION_FUNC="action_$(echo $GLOBAL_ACTION|sed 's/[-]/_/g')"
    shift
    # }}}
    # {{{
    # set up LIST_OF_REPOS
    if [[ $@ == "" ]];then
        LIST_OF_REPOS=("${DEFAULT_REPOS[@]}")
    else
        args=($@)
        LIST_OF_REPOS=("${args[@]}")
    fi
    # echo "${LIST_OF_REPOS[@]}"
    #}}}
}
#}}}


parse_commandline $@

$ACTION_FUNC
