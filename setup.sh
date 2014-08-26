#!/bin/bash

dotfiledir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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
)
cd $dotfiledir

if [[ ! -e $repodir ]];then
    mkdir $repodir;
fi

function ask_yes_no() {
    echo "$1 <yes/No>" >&2
    read yesno
    if [[ "$yesno" == "yes" ]];then
        echo "yes"
    fi
}
export -f ask_yes_no

setup_repo() {
    repo=$1
    echo "set up $repo"
    cd $repodir
    if [[ -e $repo ]];then
        echo "Repository '$repo' already exists";
        if [[ $OPT_INTERACTIVE && $(ask_yes_no "Force Pull?") = "yes" ]];then
            cd $repo
            git pull
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

function action_setup_repo() {
    local repolist=()
    if [[ "${ACTION_ARGS[0]}" ]];then
        repolist=$ACTION_ARGS
    else
        repolist=("${DEFAULT_REPOS[@]}")
    fi
    echo "Repos to load $repolist"
    for repo in ${repolist[@]};do
        echo $repo
        setup_repo $repo
    done
}

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
            local valid_action=true
            case "$1" in
                "sr"|"setup-repo")
                    GLOBAL_ACTION="setup-repo"
                    ;;
                *)
                    GLOBAL_ACTION="$DEFAULT_ACTION"
                    valid_action=false
                    ;;
            esac
            ACTION_FUNC="action_$(echo $GLOBAL_ACTION|sed 's/[-]/_/g')"
            if [[ $valid_action ]];then
                shift
            fi
        fi
    # }}}
    # {{{
    # set up ACTION_ARGS
    args=($@)
    ACTION_ARGS=("${args[@]}")
    #}}}
}

function debug() {
    echo "Action: $GLOBAL_ACTION"
    echo "Action Function: $ACTION_FUNC"
    echo "Global args: $GLOBAL_ARGS"
    echo "Action args: $ACTION_ARGS"
}

parse_commandline $@
debug

$ACTION_FUNC
