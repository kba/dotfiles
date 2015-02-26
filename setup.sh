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

dotfiledir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $dotfiledir

export OPT_INTERACTIVE
export OPT_ASSUME_DEFAULT

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
        if [[ "$OPT_ASSUME_DEFAULT" == 1 ]];then
            should_pull=true
        elif [[ $OPT_INTERACTIVE && $(ask_yes_no "Force Pull?" "yes") = "yes" ]];then
            should_pull=true
        fi
        if [[ $should_pull ]];then
            cd $repo
            git pull
            if [[ "$?" -gt 0 ]];then
                boxLeftChar 1 '  !!' "Error on `C 2`git pull`C`"
                if [[ $OPT_INTERACTIVE && $(ask_yes_no "Open shell to resolve conflicts?") = "yes" ]];then
                    $SHELL
                fi
            fi
        fi
        if [[ $OPT_INTERACTIVE && $(ask_yes_no "Force Setup?" "no") = "yes" ]];then
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
    boxFat 4 '#' "Setting up: `C 3 b` $(echo ${repolist[@]})"
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
                    "-f")
                        OPT_ASSUME_DEFAULT=true
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
# debug

$ACTION_FUNC
