#!/bin/bash

source ~/.shcolor.sh 2>/dev/null || source <(curl -s https://raw.githubusercontent.com/kba/shcolor/master/shcolor.sh|tee ~/.shcolor.sh)

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
#}}}

dotfiledir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dotfiledir

export OPT_DEBUG=false
export OPT_RECURSIVE=false
export OPT_FETCH=false
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

# now=$(date +%s%N)
now=$(date +"%Y-%m-%dT%H:%M:%SZ")

BACKUP_DIR="$dotfiledir/.backup"
[[ ! -e $BACKUP_DIR ]] && mkdir $BACKUP_DIR;

repodir=$dotfiledir/repo
LIST_OF_REPOS=()
mapfile=()
for include in $(cat REPOLIST |grep -v '^\s*#');do
    if [[ ! -s "REPOLIST.skip" ]];then
        mapfile+=($include)
    else
        grep -o "^${include}$" REPOLIST.skip >/dev/null
        if [[ $? -gt 0 ]];then
            mapfile+=($include)
        fi
    fi
done

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
    echo "`C 2`SETUP`C`"
    echo "`C 2`SETUP`C` Setting up '$repo'`C`"
    echo "`C 2`SETUP`C`"
    cd $repodir
    if [[ -e $repo ]];then
        echo "`C 1`!!`C` Repository '$repo' already exists";
        should_pull=false
        if [[ $OPT_ASSUME_DEFAULT == true || ($OPT_INTERACTIVE == true && $(ask_yes_no "Force Pull?" "yes") = "yes")]];then
            should_pull=true
        fi
        #XXX
        cd $repo
        if [[ $should_pull == true ]];then
            git pull
            if [[ "$?" -gt 0 ]];then
                echo "`C1`!!`C`  Error on `C 2`git pull`C`"
                if [[ $OPT_INTERACTIVE == true && $(ask_yes_no "Open shell to resolve conflicts?") = "yes" ]];then
                    $SHELL
                fi
            fi
        fi
        if [[ $OPT_FORCE_SETUP = true || ($OPT_INTERACTIVE == true && $(ask_yes_no "Force Setup?" "no") == "yes") ]];then
            for confdir in ".HOME" ".XDG_CONFIG_HOME";do
                targetdir=~
                if [[ $confdir == ".XDG_CONFIG_HOME" ]];then
                    targetdir=~/.config
                fi
                backup_tstamp="$BACKUP_DIR/$now/$confdir"
                # echo $backup_tstamp
                if [ -e $confdir ];then
                    for dotfile in $(find $confdir -mindepth 1 -name '*' -exec basename {} \;);do
                        backup="$backup_tstamp/$dotfile"
                        mkdir -p $backup_tstamp
                        echo "`C 3`BACKUP`C` `C 1`$targetdir/$dotfile`C` -> $backup"
                        mv -v "$targetdir/$dotfile" "$backup"
                        echo "`C 2`SYMLINK`C` $repo/$confdir/$dotfile -> `C 2`$targetdir/$dotfile`C`"
                        ln -s "$(readlink -f $confdir/$dotfile)" "$targetdir/$dotfile"
                    done
                else
                    echo "$(C 13)WARNING: No $confdir for $repo`C`"
                fi
            done
            for initsh in "init.sh" "setup.sh" "install.sh";do
                if [ -e $initsh ];then
                    source $initsh
                fi
            done
        fi
    else
        git clone "$REPO_PREFIX${repo}$REPO_SUFFIX"
        setup_repo $repo
    fi
    cd $dotfiledir
}
#}}}

#{{{
function debug() {
    echo "`C 14`DEBUG>`C` Action: $(C 5 b)$GLOBAL_ACTION $(C 3)"
    echo "`C 14`DEBUG>`C` Action Function: $ACTION_FUNC"
    echo "`C 14`DEBUG>`C` Global args: $GLOBAL_ARGS"
    echo "`C 14`DEBUG>`C`   OPT_FORCE_SETUP=$OPT_FORCE_SETUP"
    echo "`C 14`DEBUG>`C`   OPT_INTERACTIVE=$OPT_INTERACTIVE"
    echo "`C 14`DEBUG>`C`   OPT_ASSUME_DEFAULT=$OPT_ASSUME_DEFAULT"
    echo "`C 14`DEBUG>`C` Repos: $(echo ${LIST_OF_REPOS[@]})"
}
#}}}

_gitdirs() {
    if [[ $OPT_RECURSIVE == true ]];then
        find . -name '.git'
    else
        find . -maxdepth 3 -mindepth 2 -name '.git'
    fi
}
# Actions
#{{{ 
function action_usage() {
echo "`C 10`$0 `C` [-iyf] [--force-setup] <action> <repo>"
echo
echo "  `C 3`Repos:`C` [Default: all of them]"
for repo in ${LIST_OF_REPOS[@]};do
echo -e "    `C 12`$repo`C`\t     $REPO_PREFIX$repo$REPO_SUFFIX"
done;
echo
echo "  `C 3`Options:`C`"
echo "    `C 12`-i --interactive`C` interactive"
echo "    `C 12`-y --noask`C`       assume defaults (i.e. don't ask)"
echo "    `C 12`-f --force-setup`C` Setup symlinks for the repo no matter what"
echo "    `C 12`-d --debug`C`       Debug output"
echo "    `C 12`--fetch`C`          Fetch changes"
echo "    `C 12`-r --recursive`C`   Check for git repos recursively"
echo
echo "  `C 3`Actions:`C`"
echo "    `C 12`help`C`             This help screen "
echo "    `C 12`list-backups`C`     Remove all timestamped backups"
echo "    `C 12`rm-backups`C`       Remove all timestamped backups"
echo "    `C 12`setup`C`            Setup repositories"
echo "    `C 12`pull-all`C`         Pull all changes"
echo "    `C 12`push-all`C`         Push all changes"
echo "    `C 12`status`C`           Push all changes"
echo
[[ $OPT_DEBUG == true ]] && debug
exit
}
#}}}
#{{{PushPush
function action_setup() {
    boxFat 4 '#' "Setting up: `C 3 b` $(echo ${LIST_OF_REPOS[@]})`C`"
    for repo in ${LIST_OF_REPOS[@]};do
        setup_repo $repo
    done
}
#}}}
#{{{
function action_push_all() {
    local repos=()
    for gitdir in $(_gitdirs);do
        repos+=($(dirname $gitdir))
    done
    echo "`C 4`#################################`C`"
    echo "`C 4`#`C` Pushing repos: $(echo ${repos[@]}|xargs -n1 basename|xargs echo)"
    echo "`C 4`#################################`C`"
    for repo in ${repos[@]};do
        cd $repo
        echo "`C 2`>>>`C` Pushing $repo"
        git add .
        git commit -v && git push
        cd $dotfiledir
    done
}
#}}}
#{{{
function action_pull_all() {
    boxFat 4 "#" "pulling repos: $(echo ${LIST_OF_REPOS[@]})"
    local repos=()
    for gitdir in $(_gitdirs);do
        repos+=($(dirname $gitdir))
    done
    for repo in ${repos[@]};do
        cd $repo
        echo "`C 2`<<<`C` Pulling $repo"
        git pull origin master
        cd $dotfiledir
    done
}
#}}}
#{{{ 
function action_remove_backups() {
    for backup_tstamp in $BACKUP_DIR/*;do
        echo "`C 2 b`$backup_tstamp`C`"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                if [[ $OPT_ASSUME_DEFAULT == true || (\
                    $OPT_INTERACTIVE == true && $(ask_yes_no "Remove backup?" "yes") = "yes" \
                    )]];then
                echo "`C 1 b`DELETE`C` $backup"
                rm $backup
            fi
        fi
        if [[ -n "$(ls -A $backup_tstamp)" ]];then
            rmdir "$backup_tstamp";
        fi
    done
    done
}
#}}}
#{{{ 
function action_list_backups() {
    for backup_tstamp in $BACKUP_DIR/*;do
        echo "`C 2 b`$backup_tstamp`C`"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                echo -e "  $(basename $backup)"
            fi
        done
    done
}
#}}}
#{{{ 
function action_status() {
    local repos=()
    for gitdir in $(_gitdirs);do
        repos+=($(dirname $gitdir))
    done
    for repo in ${repos[@]};do
        cd $repo
        echo "`C 3`Status of `C`$repo"
        if [[ $OPT_FETCH == true ]];then
            echo -en "`C 2`git fetch ... "
            git fetch
            echo "DONE`C`"
        fi
        git status -s
        cd $dotfiledir
    done
}
#}}}

# Parse Command line arguments
#{{{
function parse_commandline() {
    # {{{
    # set up GLOBAL_ARGS 
    while (( "$#" ));do
        case "$1" in
            -*)
                case "$1" in
                    "-i"|"--interactive")
                        OPT_INTERACTIVE=true
                        ;;
                    "-f"|"--force-setup")
                        OPT_FORCE_SETUP=true
                        ;;
                    "-y"|"--noask")
                        OPT_ASSUME_DEFAULT=true
                        ;;
                    "-d"|"--debug")
                        OPT_DEBUG=true
                        ;;
                    "-r"|"--recursive")
                        OPT_RECURSIVE=true
                        ;;
                    "--fetch")
                        OPT_FETCH=true
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
    # }}}
    # {{{
    # set up $GLOBAL_ACTION
    if [[ ! -z "$1" ]];then
        case "$1" in
            "help"|"usage")
                GLOBAL_ACTION="usage"
                ;;
            "pull")
                GLOBAL_ACTION="pull-all"
                ;;
            "push")
                GLOBAL_ACTION="push-all"
                ;;
            "rm-backups")
                GLOBAL_ACTION="remove-backups"
                ;;
            *)
                GLOBAL_ACTION="$1"
                ;;
        esac
    fi
    ACTION_FUNC="action_$(echo $GLOBAL_ACTION|sed 's/[-]/_/g')"
    if [[ "$(type -t $ACTION_FUNC)" != 'function' ]];then
        echo "`C 1 b`Unknown action: '`C`$GLOBAL_ACTION`C 1b`'"
        action_usage
        exit 1
    fi
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

# main
parse_commandline $@

$ACTION_FUNC
