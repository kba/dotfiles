#!/bin/bash

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
                    mv -v "$targetdir/$dotfile" "$backup"
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

#{{{ action_setup
action_setup() {
    _log "Setting up" "${LIST_OF_REPOS[*]}"
    for repo in "${LIST_OF_REPOS[@]}";do
        _setup_repo "$repo"
    done
}
#}}}
#{{{
action_push() {
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
#}}}
#{{{
action_pull() {
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Pulling repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd $repo
        _log "git pull" "$repo"
        git pull -q --stat origin master 2>&1|_indent
    done
}
#}}}
#{{{ 
action_rm_backups() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        _log "`C 2 b`$backup_tstamp"
        for backup in $backup_tstamp/.*;do
            local do_remove=false
            if [[ ! -L $backup ]];then
                _warn "Not removing, not a symbolic link: '$backup'"
                continue
            fi
            if [[ $DOTFILES_OPT_NOASK == true ]];then
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
        _log "$backup_tstamp"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                _log "    " "$(basename "$backup")"
            fi
        done
    done
}
#}}}
#{{{ 
action_status() {
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Status'ing repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd "$repo"
        _log "git status" "$repo"
        [[ $DOTFILES_OPT_FETCH == true ]] && git fetch >/dev/null 2>&1
        git status -s|_indent
    done
}
#}}}
#{{{ 
action_usage() {
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
    echo
    echo "  `C 3`Actions:`C`"
    echo "    `C 12`setup`C`        Setup repositories"
    echo "    `C 12`list-backups`C` Remove all timestamped backups"
    echo "    `C 12`rm-backups`C`   Remove all timestamped backups"
    echo "    `C 12`pull`C`         git pull for each repo"
    echo "    `C 12`push`C`         git push for each repo"
    echo "    `C 12`status`C`       git status for each repos"
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
#}}}

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
