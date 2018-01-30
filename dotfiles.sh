#!/bin/bash
# vim: fmr={{{,}}}

#{{{ BEGIN-INCLUDE ./src/util.bash
_log() { echo -ne "$(C 4)$1$(C) "; shift; echo -e "$*"; }
_logn() { echo -ne "$(C 4)$1$(C) "; shift; echo -ne "$*"; }
_error() { _log "$(C 1 b)ERROR" "$*"; }
_warn() { echo "$(C 3)WARN$(C) $*"; }
_indent() { local indent=${1:-    }; local line; while read line;do echo -e "${indent}$line";done; }
_remove_path_tail_filter() { sed 's,/[^/]*/\?$,,g'; }
_remove_path_head() { for p in "$@";do echo -n "${p##*/} ";done; }

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

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/select.bash
subcommand::select::description() {
    echo "Interactively select repos"
}

subcommand::select() {
    cd "$DOTFILEDIR"
    local repos=($(cat REPOLIST.*|sort|uniq))
    if [[ -e REPOLIST ]];then
        echo "`C 1`WARNING`C` This will clobber your existing REPOLIST. Press Ctrl-C to cancel"
        read
    fi
    echo > REPOLIST
    for repo in ${repos[@]};do
        echo -n "[ ] $repo"
        read -n1 -p " [yN] > "  yesno;
        if [[ "$yesno" != "y" && "$yesno" != "n" ]];then
            yesno="y"
        fi
        if [[ "$yesno" = "y" ]];then
            echo -e "\r[x]"
        else
            echo -e "\r[ ]"
            echo -n "# " >> REPOLIST
        fi
        echo "$repo" >> REPOLIST
    done
    echo "Written to $DOTFILEDIR/REPOLIST"
}

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/setup.bash
subcommand::setup::description() {
    echo Setup repositories
}

subcommand::setup() {
    _log "Setting up" "${LIST_OF_REPOS[*]}"
    for repo in "${LIST_OF_REPOS[@]}";do
        _setup_repo "$repo"
    done
}

_setup_repo() {
    repo=$1
    local repo_url="$DOTFILES_REPO_PREFIX${repo}$DOTFILES_REPO_SUFFIX"
    _log "SETUP" "Setting up '$repo'"
    cd "$DOTFILES_REPODIR"

    local cloned=false
    local should_pull=false

    # Try to clone
    if [[ ! -e $repo ]];then
        git clone --depth 5 "$repo_url"
        if [[ ! -e $repo ]];then
            _error "Could not pull $repo_url"
            return 1
        fi
        cloned=true
    else
        # If already exists, check whether to pull
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

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/push.bash
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

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/pull.bash
subcommand::pull::description() {
    echo "Pull all repos"
}

subcommand::pull() {
    local repos=($(_gitdirs "${LIST_OF_REPOS[@]}"))
    # shellcheck disable=SC2001 disable=SC2046
    _log "Pulling repos" $(_remove_path_head "${repos[@]}")
    for repo in "${repos[@]}";do
        cd $repo
        _log "git pull" "$repo"
        git pull -q --stat origin master 2>&1|_indent
    done
}

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/bak-rm.bash


#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/bak-ls.bash
subcommand::bak-ls::description() {
    echo "List all timestamped backups"
}

subcommand::bak-ls() {
    for backup_tstamp in $DOTFILES_BACKUPDIR/*;do
        _log "$backup_tstamp"
        for backup in $backup_tstamp/.*;do
            if [[ -L $backup ]];then
                _log "    " "$(basename "$backup")"
            fi
        done
    done
}

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/status.bash
subcommand::status::description () {
    echo "Repo status"
}
subcommand::status() {
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

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/usage.bash
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

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/archive.bash
subcommand::archive::description() {
    echo "Create an archive of current state"
}
subcommand::archive() {
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

#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/find.bash
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

#}}} END-INCLUDE

#{{{ main
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
            -*)                   _error "Unknown Option '$1'"; subcommand::usage; exit 1 ;;
            *)                    posargs+=("$1")
        esac
        shift
    done

    set -- "${posargs[@]}"
    export GLOBAL_ACTION="${1:-usage}"
    shift

    export SUBCOMMAND="subcommand::${GLOBAL_ACTION}"
    if [[ "$(type -t "$SUBCOMMAND")" != 'function' ]];then
        _error "Unknown action: $GLOBAL_ACTION"
        subcommand::usage
        exit 1
    fi

    if [[ $# == 0 ]];then
        LIST_OF_REPOS=("${DEFAULT_REPOS[@]}")
    else
        LIST_OF_REPOS=("$@")
    fi

    $SUBCOMMAND
}

#}}}
#{{{ BEGIN-INCLUDE ./src/configuration.bash
export DOTFILEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DOTFILEDIR"

source "$DOTFILEDIR/shcolor.sh"
source "$DOTFILEDIR/profile.default.sh"

[[ ! -e "$DOTFILES_REPODIR"     ]] && mkdir "$DOTFILES_REPODIR"
[[ ! -e "$DOTFILES_BACKUPDIR"   ]] && mkdir "$DOTFILES_BACKUPDIR";
[[ -e "$DOTFILES_LOCAL_PROFILE" ]] && source "$DOTFILES_LOCAL_PROFILE"

#}}} END-INCLUDE
#{{{ LIST_OF_REPOS
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

