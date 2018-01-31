#!/bin/bash
# vim: fmr={{{,}}}

#{{{ BEGIN-INCLUDE ./src/util.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/select.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/clone.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/push.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/pull.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/bak-rm.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/bak-ls.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/status.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/usage.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/archive.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/find.bash
#}}} END-INCLUDE
#{{{ BEGIN-INCLUDE ./src/subcommand/init.bash
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

    if (( $# > 0 ));then
        export LIST_OF_REPOS=("$@")
    fi

    $SUBCOMMAND
}

#}}}
#{{{ BEGIN-INCLUDE ./src/configuration.bash
#}}} END-INCLUDE

now=$(date +"%Y-%m-%dT%H-%M-%SZ")
main "$@"

