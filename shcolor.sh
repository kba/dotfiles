test -t 1 || COLORS_ENABLED=false
__ESC_SEQ="\x1b["
__cReset="${__ESC_SEQ}39;49m"
__cBold=";1"
__cItalic=";3"
__cUnderline=";4"
__cStopBold="${__ESC_SEQ}24m"
__cStopItalic="${__ESC_SEQ}21m"
__cStopUnderline="${__ESC_SEQ}21m"
__cForeground="${__ESC_SEQ}3"
__cForeground256="${__ESC_SEQ}38;5;"
__cBackground="${__ESC_SEQ}4"
__cBackground256="${__ESC_SEQ}48;5;"

_internalC() {
    local whichground=$1
    local color=$2
    local bold=$3
    local italic=$4
    local underline=$5

    local flag256=""
    local output=""

    local ACTUAL_SHELL=
    [[ ! -z "$BASH" ]]        && ACTUAL_SHELL="bash"
    [[ ! -z "$ZSH_VERSION" ]] && ACTUAL_SHELL="zsh"

    [[ "$color" =~ ^[0-9]{2,3}$ ]] && flag256=256

    local varname="__c${whichground}ground${flag256}"

    [[ "$ACTUAL_SHELL" == "zsh"  ]] && output="${(P)varname}$color"
    [[ "$ACTUAL_SHELL" == "bash" ]] && output="${!varname}$color"

    [[ "$underline" == 1 ]] && output="${output}${__cUnderline}"
    [[ "$italic" == 1 ]] && output="${output}${__cUnderline}"
    [[ "$bold"      == 1 ]] && output="${output}${__cBold}"
    output="${output}m"
    echo -ne "$output"
}
C() {
  if [[ "$COLORS_ENABLED" == false ]];then
    return
  fi
    local bold="0"
    local italic="0"
    local underline="0"
    if [[ -z "$1" ]];then
        echo -ne "${__cStopBold}"
        echo -ne "${__cStopItalic}"
        echo -ne "${__cStopUnderline}"
        echo -ne "${__cReset}"
        return
    elif [[ "$1" == "-" ]];then
        shift
    else
        local color=$1
        if [[ "$2" == "b" ]];then
            bold=1
            shift
        fi
        if [[ "$2" == "i" ]];then
            italic=1
            shift
        fi
        if [[ "$2" == "u" ]];then
            underline=1
            shift
        fi
        _internalC "Fore" $color "$bold" "$underline"
        shift
    fi
    if [[ ! -z $1 ]];then
        _internalC "Back" $1
    fi
}

Cecho() {
    $fmt = $1
    $msg = $2
    echo "`C $fmt`$msg`C`"
}
