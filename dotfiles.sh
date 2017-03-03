#!/bin/bash

#
# Helper functions
# Utility functions for drawing stuff
#
#{{{ 
_textWidthWithoutEscapeCodes() {
    local message=$(echo "$1"|sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
    local padding=3
    [[ $2 ]] && padding=$2
    local messageLength=$(echo "$message"|wc -c)
    messageLength=$(( messageLength + padding ))
    echo $messageLength
}
#}}}
#{{{ 
_colorecho() {
    echo -ne "$(C "$2")$1"
}
#}}} 
#{{{
_error() {
  echo "$(C 1 b)ERROR$(C) $*";
}
#}}} 
#{{{
_warn() {
  echo "$(C 4)!!$(C) $*";
}
#}}} 
#{{{
_info() {
    echo -ne "$(C 2)$1$(C)"
    shift
    echo -e "$*"
}
#}}} 
#{{{ 
_box_fat() {
    local color=$1
    local char=$2
    local message=$3
    local width=$(_textWidthWithoutEscapeCodes "$message" 4)
    echo -ne "$(C "$color")"
    # shellcheck disable=SC2034
    for i in $(seq "$width");do echo -ne "$2"; done
    echo
    _colorecho "$char" "$color"
    _colorecho " $message "
    echo -ne "$(C 0)"
    _colorecho "$char" "$color"
    echo
    echo -ne "$(C "$color")"
    # shellcheck disable=SC2034
    for i in $(seq "$width");do echo -ne "$2"; done
    # shellcheck disable=SC2005
    echo "$(C)"
}
#}}}
#{{{
_ask_yes_no() {
    default_to_yes=$2
    if [[ ! -z $default_to_yes && "$default_to_yes" == "yes" ]];then
        echo -n "$(C 87 b)??$(C) $1 < $(C 1)Y$(C)es/o> " >&2
        read yesno
        if [[ -z "$yesno" || "$yesno" == "yes" || "$yesno" == "y" ]];then
            echo "yes"
            return 1
        fi
    else
        echo -n "$(C 87 b)??$(C) $1 <yes/$(C 1)N$(C)o> " >&2
        read yesno
        if [[ "$yesno" == "yes" || "$yesno" == "y" ]];then
            echo "yes"
            return 1
        fi
    fi
}
export -f _ask_yes_no
#}}}
#{{{
_debug() {
    (
        env | grep '^DOTFILES'|sort
        echo "LIST_OF_REPOS=${LIST_OF_REPOS[*]}"
        echo "GLOBAL_ARGS=${GLOBAL_ARGS[*]}"
        echo "GLOBAL_ACTION=$GLOBAL_ACTION"
        echo "ACTION_FUNC=$ACTION_FUNC"
    ) | while read decl;do
        local k=${decl%%=*}
        local v=${decl##*=}
        _info "$k" "=$v"
    done|column -s= -t
}
#}}}
#{{{
_gitdirs() {
    if [[ $DOTFILES_OPT_RECURSIVE == true ]];then
        find . -name '.git'
    else
        find . -maxdepth 3 -mindepth 2 -name '.git'
    fi
}
#}}}
#{{{
_setup_repo() {
    repo=$1
    _info "SETUP"
    _info "SETUP" "Setting up '$repo'"
    _info "SETUP"
    cd "$DOTFILES_REPODIR"

    cloned=false
    should_pull=false

    # Try to clone
    if [[ ! -e $repo ]];then
        git clone --depth 5 "$DOTFILES_REPO_PREFIX${repo}$DOTFILES_REPO_SUFFIX"
        if [[ ! -e $repo ]];then
            _error "Could not pull $DOTFILES_REPO_PREFIX${repo}$DOTFILES_REPO_SUFFIX"
            exit 1
        fi
        cloned=true
    else
        # If alreayd exists, check whether to pull
        _warn "Repository '$repo' already exists"
        if [[ $DOTFILES_OPT_FORCE == true || $DOTFILES_OPT_ASSUME_DEFAULT == true ]];then
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
            # echo $backup_tstamp
            if [ -e $confdir ];then
                # shellcheck disable=SC2044
                for dotfile in $(find "$confdir" -mindepth 1 -name '*' -exec basename {} \;);do
                    backup="$backup_tstamp/$dotfile"
                    mkdir -p "$backup_tstamp"
                    echo "$(C 3)BACKUP$(C) $(C 1)$targetdir/$dotfile$(C) -> $backup"
                    mv -v "$targetdir/$dotfile" "$backup"
                    echo "$(C 2)SYMLINK$(C) $repo/$confdir/$dotfile -> $(C 2)$targetdir/$dotfile$(C)"
                    ln -s "$(readlink -f "$confdir/$dotfile")" "$targetdir/$dotfile"
                done
            else
                echo "$(C 13)WARNING: No $confdir for $repo$(C)"
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
#}}}


#
# Actions
#
#{{{ action_setup
action_setup() {
    _box_fat 4 '#' "Setting up: `C 3 b` ${LIST_OF_REPOS[*]}`C`"
    for repo in "${LIST_OF_REPOS[@]}";do
        _setup_repo "$repo"
    done
}
#}}}
#{{{
action_push_all() {
    local repos=()
    for gitdir in $(_gitdirs);do
        repos+=($(dirname "$gitdir"))
    done
    echo "`C 4`#################################`C`"
    echo "`C 4`#`C` Pushing repos: $(echo ${repos[@]}|xargs -n1 basename|xargs echo)"
    echo "`C 4`#################################`C`"
    for repo in ${repos[@]};do
        cd $repo
        echo "`C 2`>>>`C` Pushing $repo"
        git add .
        git commit -v && git push
        cd "$DOTFILEDIR"
    done
}
#}}}
#{{{
action_pull_all() {
    _box_fat 4 "#" "pulling repos: $(echo ${LIST_OF_REPOS[@]})"
    local repos=()
    for gitdir in $(_gitdirs);do
        repos+=($(dirname "$gitdir"))
    done
    for repo in ${repos[@]};do
        cd $repo
        echo "`C 2`<<<`C` Pulling $repo"
        git pull origin master
        cd "$DOTFILEDIR"
    done
}
#}}}
#{{{ 
action_remove_backups() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        echo "`C 2 b`$backup_tstamp`C`"
        for backup in $backup_tstamp/.*;do
            local do_remove=false
            if [[ ! -L $backup ]];then
                _warn "Not removing, not a symbolic link: '$backup'"
                continue
            fi
            if [[ $DOTFILES_OPT_ASSUME_DEFAULT == true ]];then
                do_remove=true
            elif [[ $DOTFILES_OPT_INTERACTIVE == true ]];then
                _ask_yes_no "Remove backup?" && do_remove=true
            fi
            if [[ "$do_remove" == true ]];then
                _warn "DELETE '$backup'"
                rm "$backup"
            fi
        done
        if [[ -n "$(ls -A "$backup_tstamp")" ]];then
            rmdir "$backup_tstamp";
        fi
    done
}
#}}}
#{{{ 
action_list_backups() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        echo "`C 2 b`$backup_tstamp`C`"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                echo -e "  $(basename "$backup")"
            fi
        done
    done
}
#}}}
#{{{ 
action_status() {
    local repos=()
    for gitdir in $(_gitdirs);do
        repos+=($(dirname "$gitdir"))
    done
    for repo in "${repos[@]}";do
        cd $repo
        echo "`C 3`Status of `C`$repo"
        if [[ $DOTFILES_OPT_FETCH == true ]];then
            echo -en "`C 2`git fetch ... "
            git fetch
            echo "DONE`C`"
        fi
        git status -s
        cd "$DOTFILEDIR"
    done
}
#}}}
#{{{ 
action_usage() {
  echo "`C 10`$0 `C` [-iyf] [--force-setup] <action> <repo>"
  echo
  echo "  `C 3`Repos:`C` [Default: all of them]"
  for repo in "${LIST_OF_REPOS[@]}";do
    echo -e "    `C 12`$repo`C`\t     $DOTFILES_REPO_PREFIX$repo$DOTFILES_REPO_SUFFIX"
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
  echo "    `C 12`setup`C`            Setup repositories"
  echo "    `C 12`debug`C`            This help screen "
  echo "    `C 12`help`C`             This help screen "
  echo "    `C 12`list-backups`C`     Remove all timestamped backups"
  echo "    `C 12`rm-backups`C`       Remove all timestamped backups"
  echo "    `C 12`pull-all`C`         Pull all changes"
  echo "    `C 12`push-all`C`         Push all changes"
  echo "    `C 12`status`C`           Push all changes"
  echo
  [[ $DOTFILES_OPT_DEBUG == true ]] && _debug
  exit
}
#}}}

#
# Parse Command line arguments
#
#{{{
parse_commandline() {
    # {{{
    # set up GLOBAL_ARGS 
    while (( "$#" ));do
        case "$1" in
            -*)
                case "$1" in
                    "-i"|"--interactive")
                        DOTFILES_OPT_INTERACTIVE=true
                        ;;
                    "-f"|"--force-setup")
                        DOTFILES_OPT_FORCE=true
                        ;;
                    "-y"|"--noask")
                        DOTFILES_OPT_ASSUME_DEFAULT=true
                        ;;
                    "-d"|"--debug")
                        DOTFILES_OPT_DEBUG=true
                        ;;
                    "-r"|"--recursive")
                        DOTFILES_OPT_RECURSIVE=true
                        ;;
                    "--fetch")
                        DOTFILES_OPT_FETCH=true
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
    # ACTION_FUNC="action_$(echo "$GLOBAL_ACTION"|sed 's/[-]/_/g')"
    ACTION_FUNC="action_${GLOBAL_ACTION//-/_}"
    if [[ "$(type -t "$ACTION_FUNC")" != 'function' ]];then
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
        args=("$@")
        LIST_OF_REPOS=("${args[@]}")
    fi
    # echo "${LIST_OF_REPOS[@]}"
    #}}}
}
#}}}

#
# Configuration 
#
#{{{
export DOTFILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DOTFILEDIR"

source "$DOTFILEDIR/shcolor.sh"
source "$DOTFILEDIR/profile.default.sh"

[[ ! -e "$DOTFILES_REPODIR"     ]] && mkdir "$DOTFILES_REPODIR"
[[ ! -e "$DOTFILES_BACKUPDIR"   ]] && mkdir "$DOTFILES_BACKUPDIR";
[[ -e "$DOTFILES_LOCAL_PROFILE" ]] && source "$DOTFILES_LOCAL_PROFILE"

# The global action
export GLOBAL_ACTION="usage"

# The 
export GLOBAL_ARGS=()
export ACTION_FUNC

LIST_OF_REPOS=()
typeset -a DEFAULT_REPOS
# shellcheck disable=SC2013
for include in $(grep -v '^\s*#' REPOLIST);do
    if [[ ! -s "REPOLIST.skip" ]];then
        DEFAULT_REPOS+=($include)
    else
        grep -o "^${include}$" REPOLIST.skip >/dev/null
        if [[ $? -gt 0 ]];then
            DEFAULT_REPOS+=($include)
        fi
    fi
done
#}}}

# now=$(date +%s%N)
now=$(date +"%Y-%m-%dT%H:%M:%SZ")

parse_commandline "$@"

$ACTION_FUNC
