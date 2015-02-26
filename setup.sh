#!/bin/bash

source <(curl -s "https://raw.githubusercontent.com/kba/shcolor/master/shcolor.sh")

export SHBOOTRC_RUNNING=true

echoe() {
    echo -e $*
}
echoec() {
    echo -ne $*
    echo -ne `C`
    echo
}
boxFat() {
    color=$1
    char=$2
    message=$3
    width=$(echo $(echo -E $message|wc -c) + 3|bc)
    echo -ne $(C $color)
    for i in $(seq $width);do
        echo -ne $2
    done
    echo
    echo -ne "`C $color`$char"
    echo -n "`C` $message "
    echo -e "`C $color`$char"
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

dotfiledir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dotfiledir

export OPT_INTERACTIVE

export REPO_PREFIX="https://github.com/kba/"
export REPO_SUFFIX=".git"

# The global action
export DEFAULT_ACTION="setup-repo"
export GLOBAL_ACTION

# The 
export ORIG_ARGS
export GLOBAL_ARGS=()
export ACTION_ARGS=()
export ACTION_FUNC

repodir=$dotfiledir/repo
DEFAULT_REPOS=(
    antigen-config
    zsh-config
    vim-config
    home-bin
    tmux-config
)

if [[ ! -e $repodir ]];then
    mkdir $repodir;
fi

function ask_yes_no() {
    echo -n "`C 87 b`??`C` $1 <yes/`C 1`N`C`o> " >&2
    read yesno
    if [[ "$yesno" == "yes" || "$yesno" == "y" ]];then
        echo "yes"
    fi
}
export -f ask_yes_no

#{{{
setup_repo() {
    repo=$1
    boxLeftChar 2 '>>>'
    boxLeftChar 2 '>>>' "Setting up '$repo'"
    boxLeftChar 2 '>>>'
    cd $repodir
    if [[ -e $repo ]];then
        boxLeftChar 1 '!!' "Repository '$repo' already exists";
        if [[ $OPT_INTERACTIVE && $(ask_yes_no "Force Pull?") = "yes" ]];then
            cd $repo
            git pull
            if [[ "$?" ]];then
                boxLeftChar 1 '  !!' "Error on `C 2`git pull`C`"
                if [[ $OPT_INTERACTIVE && $(ask_yes_no "Open shell to resolve conflicts?") = "yes" ]];then
                    $SHELL
                fi
            fi
        fi
        if [[ $OPT_INTERACTIVE && $(ask_yes_no "Force Setup?") = "yes" ]];then
            cd $repo
            source setup.sh
        fi
    else
        git clone "$REPO_PREFIX${repo}$REPO_SUFFIX"

        ## XXX
        # NESTED
        cd $repo
        source setup.sh
    fi
    cd $dotfiledir
}
#}}}
#{{{
function action_setup_repo() {
    local repolist=()
    if [[ -n "$ACTION_ARGS" ]];then
        repolist=("${ACTION_ARGS[@]}")
    else
        repolist=("${DEFAULT_REPOS[@]}")
    fi
    boxFat 3 '#' "Setting up: `C 3 b` $(echo ${repolist[@]})"
    for repo in ${repolist[@]};do
        # echo $repo
        setup_repo $repo
    done
}
#}}}
#{{{
function action_push_all() {
    local repolist=()
    if [[ -n "$ACTION_ARGS" ]];then
        repolist=("${ACTION_ARGS[@]}")
    else
        repolist=("${DEFAULT_REPOS[@]}")
    fi
    boxFat 4 "#" "Pushing repos: $(echo ${repolist[@]})"
    for repo in ${repolist[@]};do
        cd repo/$repo
        boxLeftChar 2 '>>>'
        boxLeftChar 2 '>>>' "Pushing $repo"
        boxLeftChar 2 '>>>'
        git add -A .
        git commit -v && git push
        cd $dotfiledir
    done
}
#}}}
#{{{
function parse_commandline() {
    local args=$@
    # {{{
    # remember ORIG_ARGS
    ORIG_ARGS=("${args[@]}")
    readonly ORIG_ARGS
    #}}}
    # {{{
    # set up GLOBAL_ARGS 
    while (( "$#" ));do
        case "$1" in
            -*)
                case "$1" in
                    "-i")
                        OPT_INTERACTIVE=true
                        ;;
                esac
                GLOBAL_ARGS+=$1
                ;;
                # TODO GLOBAL_ACTION
                *)
                break
                ;;
        esac
        shift
    done
    # }}}
    # {{{
    # set up $GLOBAL_ACTION
        if [[ -z "$1" ]];then
            GLOBAL_ACTION="$DEFAULT_ACTION"
        else
            local is_valid_action=true
            case "$1" in
                "sr"|"setup-repo")
                    GLOBAL_ACTION="setup-repo"
                    ;;
                "push"|"push-all")
                    GLOBAL_ACTION="push-all"
                    ;;
                *)
                    GLOBAL_ACTION="$DEFAULT_ACTION"
                    is_valid_action=
                    ;;
            esac
            ACTION_FUNC="action_$(echo $GLOBAL_ACTION|sed 's/[-]/_/g')"
            if [[ $is_valid_action ]];then
                shift
            fi
        fi
    # }}}
    # {{{
    # set up ACTION_ARGS
    echo $@
    args=($@)
    ACTION_ARGS=("${args[@]}")
    #}}}
}
#}}}
#{{{
function debug() {
    echo -e "$(C 3)"
    echo "Action: $(C 5 b)$GLOBAL_ACTION $(C 3)"
    echo "Action Function: $ACTION_FUNC"
    echo "Global args: $GLOBAL_ARGS"
    echo "Action args: $ACTION_ARGS"
    echo -e "$(C)"
}
#}}}

parse_commandline $@
debug

$ACTION_FUNC
