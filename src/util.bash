_log() { echo -ne "$(C 4)$1$(C) "; shift; echo -e "$*"; }
_logn() { echo -ne "$(C 4)$1$(C) "; shift; echo -ne "$*"; }
_error() { _log "$(C 1 b)ERROR" "$*"; }
_warn() { echo "$(C 3)WARN$(C) $*"; }
_indent() { local indent=${1:-    }; local line; while read line;do echo -e "${indent}$line";done; }
_remove_path_tail_filter() { sed 's,/[^/]*/\?$,,g'; }
_remove_path_head() { for p in "$@";do echo -n "${p##*/} ";done; }

#{{{ util::symlink
util::symlink () {
for confdir in ".HOME" ".XDG_CONFIG_HOME";do
    targetdir=~
    if [[ $confdir == ".XDG_CONFIG_HOME" ]];then
        targetdir=~/.config
    fi
    if [ -e $confdir ];then
        # shellcheck disable=SC2044
        for dotfile in $(find "$confdir" -mindepth 1 -name '*' -exec basename {} \;);do
            _log "SYMLINK" "$repo/$confdir/$dotfile -> $(C 2)$targetdir/$dotfile$(C)"
            ln -fs "$(readlink -f "$confdir/$dotfile")" "$targetdir/$dotfile"
        done
    fi
done
}
#}}}
#{{{ util::backup
util::backup () {
    local now=$1
    cd "$2"
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
                mv -f "$targetdir/$dotfile" "$backup"
            done
        fi
    done
}
#}}}
#{{{ util::ensure-repo-list
util::ensure-repo-list () {
    if [[ "$LIST_OF_REPOS" != "" ]];then
        return
    fi
    if [[ ! -e REPOLIST || -z REPOLIST ]];then
        subcommand::select
    fi
    _log 'REPOS' 'Reading LIST_OF_REPOS from REPOLIST'

    LIST_OF_REPOS=()
    # shellcheck disable=SC2013
    for include in $(grep -v '^\s*#' REPOLIST);do
        if [[ ! -s "REPOLIST.skip" ]];then
            LIST_OF_REPOS+=($include)
        else
            if ! grep -qo "^${include}$" REPOLIST.skip;then
                LIST_OF_REPOS+=($include)
            fi
        fi
    done
}
#}}}
#{{{ _ask_yes_no
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
#{{{ _debug
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
#{{{ _gitdirs
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

