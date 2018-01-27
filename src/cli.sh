#!/bin/bash
# vim: fmr={{{,}}}

#{{{
_log() { echo -ne "$(C 4)$1$(C) "; shift; echo -e "$*"; }
_logn() { echo -ne "$(C 4)$1$(C) "; shift; echo -ne "$*"; }
_error() { _log "$(C 1 b)ERROR" "$*"; }
_warn() { echo "$(C 3)WARN$(C) $*"; }
_indent() { local indent=${1:-    }; local line; while read line;do echo -e "${indent}$line";done; }
_remove_path_tail_filter() { sed 's,/[^/]*/\?$,,g'; }
_remove_path_head() { for p in "$@";do echo -n "${p##*/} ";done; }
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
    (   env | grep '^DOTFILES'|sort
        echo "LIST_OF_REPOS=${LIST_OF_REPOS[*]}"
        echo "GLOBAL_ACTION=$GLOBAL_ACTION"
        echo "ACTION_FUNC=$ACTION_FUNC"
    ) | while read decl;do
        local k=${decl%%=*}
        local v=${decl##*=}
        _log "$k" "=$v"
    done|column -s= -t
}
#}}}
#{{{
_gitdirs() {
    if [[ "$DOTFILES_OPT_ALL" == true ]];then
        if [[ $DOTFILES_OPT_RECURSIVE == true ]];then
            find "$DOTFILEDIR" -name '.git'|_remove_path_tail_filter
        else
            find "$DOTFILEDIR" -maxdepth 3 -mindepth 2 -name '.git'|_remove_path_tail_filter
        fi
    else
        for repo in "${LIST_OF_REPOS[@]}";do
            echo "$DOTFILES_REPODIR/$repo"
        done
    fi
}
#}}}
#{{{
_setup_repo() {
    repo=$1
    _log "SETUP" "Setting up '$repo'"
    cd "$DOTFILES_REPODIR"

    local cloned=false
    local should_pull=false

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
#}}}

#{{{ BEGIN-INCLUDE ./src/action/setup.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/push.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/pull.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/list_backups.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/rm_backups.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/status.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/usage.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/action/archive.bash
#}}} END-INCLUDE

# {{{
main() {

    declare -a posargs=()
    while (( "$#" ));do
        case "$1" in
            "-i"|"--interactive") DOTFILES_OPT_INTERACTIVE=true ;;
            "-f"|"--force-setup") DOTFILES_OPT_FORCE=true ;;
            "-y"|"--noask")       DOTFILES_OPT_NOASK=true ;;
            "-a"|"--all")         DOTFILES_OPT_ALL=true ;;
            "-d"|"--debug")       DOTFILES_OPT_DEBUG=true ;;
            "-r"|"--recursive")   DOTFILES_OPT_RECURSIVE=true ;;
            "-F"|"--fetch")       DOTFILES_OPT_FETCH=true ;;
            -*)                   _error "Unknown Option '$1'"; action_usage; exit 1 ;;
            *)                    posargs+=("$1")
        esac
        shift
    done

    set -- "${posargs[@]}"
    export GLOBAL_ACTION="${1:-usage}"
    shift

    export ACTION_FUNC="action_${GLOBAL_ACTION//-/_}"
    if [[ "$(type -t "$ACTION_FUNC")" != 'function' ]];then
        _error "Unknown action: $GLOBAL_ACTION"
        action_usage
        exit 1
    fi

    if [[ $# == 0 ]];then
        LIST_OF_REPOS=("${DEFAULT_REPOS[@]}")
    else
        LIST_OF_REPOS=("$@")
    fi

    $ACTION_FUNC
}

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
#}}}

LIST_OF_REPOS=()
typeset -a DEFAULT_REPOS
# shellcheck disable=SC2013
for include in $(grep -v '^\s*#' REPOLIST);do
    if [[ ! -s "REPOLIST.skip" ]];then
        DEFAULT_REPOS+=($include)
    else
        if ! grep -qo "^${include}$" REPOLIST.skip;then
            DEFAULT_REPOS+=($include)
        fi
    fi
done

#}}}

now=$(date +"%Y-%m-%dT%H-%M-%SZ")
main "$@"

