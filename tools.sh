#!/bin/bash

# execute as: ". <tools.sh> [options]"
# shortest version:
#       . "`dirname $0`/tools.sh"
# shortest version with tools known arguments processed:
#       . "`dirname $0`/tools.sh" "$@"
# shortest version with arguments set to variables:
#       . "`dirname $0`/tools.sh" -- "$@"
# good version:
#       export TOOLS_FILE="`dirname $0`/tools.sh"
#       . "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }
# long version:
#       unset TOOLS_LOADED
#       export TOOLS_FILE="`dirname $0`/tools.sh"
#       . "$TOOLS_FILE" --debug --debug-right --debug-function --debug-variable "$@"
#       test "$TOOLS_LOADED" != "yes" && echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1

# options:
# --prefix
# --color[=yes|no]
# --uname=yes|no
# combinations for example for color:
# -c
# -c no
# -c yes
# --color
# --color=yes
# --color=no
# etc...

declare -x TOOLS_LOADED="yes"

shopt -s extglob
#export LC_ALL=C

#"Linux RedHat CentOS"
#"Linux SuSE openSUSE"

function fill_unix_type
{
    test $# -eq 3 && UNIX_TYPE="$1" && shift
    UNIX_DISTRO_MAIN="$1"
    UNIX_DISTRO_SUB="$2"
}

fill_unix_type "`uname`" "" ""

test -f "/etc/SuSE-release" && fill_unix_type "SuSE" "`awk 'BEGIN { FS="="; } /^NAME=/ { print $2; }' "/etc/os-release"`"
test -f "/etc/SuSE-release" && fill_unix_type "SuSE" "`awk '/SUSE Linux Enterprise Server/ { print "SLES"; } /openSUSE/ { print "openSUSE"; }' "/etc/SuSE-release"`"
test -f "/etc/redhat-release" && fill_unix_type "RedHat" "`awk '/Red Hat Enterprise Linux Server/ { print "RHEL"; }' "/etc/redhat-release"`"
test -f "/etc/centos-release" && fill_unix_type "RedHat" "CentOS"
test -f "/etc/OEL-release" && fill_unix_type "RedHat" "OEL"

if test "$UNIX_TYPE" = "SunOS"
then
    declare -x RM="rm"
    declare -x AWK="/usr/bin/nawk"
    declare -x GREP="/usr/xpg4/bin/grep"
    declare -x SSH="ssh -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SSHq="$SSH -q"
    declare -x SCP="scp -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SCPq="$SCP -q"
fi
if test "$UNIX_TYPE" = "Linux"
then
    declare -x RM="/bin/rm -f"
    declare -x AWK="/bin/awk"
    type awk > /dev/null 2>&1 && declare -x AWK="`type -P awk`"
    declare -x GREP="/bin/grep"
    type grep > /dev/null 2>&1 && declare -x GREP="`type -P grep`"
    #declare -x SSH="ssh -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SSH="ssh -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SSHb="ssh -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SSHq="$SSH -q"
    declare -x SSHbq="$SSHb -q"
    #declare -x SCP="scp -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SCP="scp -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SCPb="scp -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    declare -x SCPq="$SCP -q"
    declare -x SCPbq="$SCPb -q"
fi

function query
{
    local QUESTION="$1"
    local ERROR="$2"
    if test "${3:0:1}" = "#"
    then
        local TEST_FUNCTION="${3:1}"
        local TEST_REGEXP=".*"
    else
        local TEST_FUNCTION=""
        local TEST_REGEXP="$3"
    fi
    test -z "$TEST_REGEXP" && TEST_REGEXP=".*"
    DEFAULT="$4"
    export REPLY=""
    export QUERY_REPLY=""

    if test -z "$DEFAULT"
    then
        QUERY="$QUESTION"
    else
        QUERY="$QUESTION (default: $DEFAULT)"
    fi

    if test "$UNIX_TYPE" = "SunOS"
    then
        OK="no"
        until test "$OK" = "ok"
        do
            if test -z "$DEFAULT"
            then
                REPLY=`ckstr -Q -r "$TEST_REGEXP" -p "$QUERY" -e "$ERROR"`
            else
                REPLY=`ckstr -Q -r "$TEST_REGEXP" -p "$QUERY" -e "$ERROR" -d "$DEFAULT"`
            fi

            if test "$TEST_FUNCTION" = "PING"
            then
                ping -c 2 "$REPLY" > /dev/null 2>&1
                test $? -eq 0 && OK="ok"
                test_no "$OK" && echo "        Error: $ERROR"
            else
                OK="ok"
            fi
        done
    fi

    if test "$UNIX_TYPE" = "Linux"
    then
        OK="no"
        until test "$OK" = "ok"
        do
            read -e -p "$QUERY [?] "
            if test -z "$REPLY"
            then
                REPLY="$DEFAULT"
            fi

            if test "$TEST_FUNCTION" = "PING"
            then
                ping -c 2 "$REPLY" > /dev/null 2>&1
                test $? -eq 0 && OK="ok"
            else
                OK="`echo "$REPLY" | $AWK '/'$TEST_REGEXP'/ { print "ok"; exit } { print "no" }'`"
            fi
            test_no "$OK" && echo "        Error: $ERROR"
        done
    fi

    export REPLY
    export QUERY_REPLY="$REPLY"
    #echo $REPLY
}

function query_yn
{
    query "$1" "Enter y or n" "y|yes|n|no" "yes"
    test "$REPLY" = "y" -o "$REPLY" = "yes" && return 0
    return 1
}

function query_ny
{
    query "$1" "Enter y or n" "y|yes|n|no" "no"
    test "$REPLY" = "y" -o "$REPLY" = "yes" && return 0
    return 1
}

function command_options
{
    local TASK="$1"
    shift
    if test "$TASK" = "fill"
    then
        COMMAND="$1"
        OPTIONS="$2 $3 $4 $5 $6 $7 $8 $9"
        OPTIONS2="$3 $4 $5 $6 $7 $8 $9 ${10}"
        OPTIONS3="$4 $5 $6 $7 $8 $9 $10 ${11}"
        OPTIONS4="$5 $6 $7 $8 $9 $10 $11 ${12}"
        OPTION="$2"
        OPTION1="$2"
        OPTION2="$3"
        OPTION3="$4"
        OPTION4="$5"
        OPTION5="$6"
        OPTION6="$7"
        OPTION7="$8"
        OPTION8="$9"
        OPTION9="${10}"
        OPTIONS_A=("$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}")
    fi
    if test "$TASK" = "parse"
    then
        COMMAND="`str_get_arg "$INPUT" 1`"
        OPTIONS="`str_get_arg_from "$INPUT" 2`"
        OPTIONS2="`str_get_arg_from "$INPUT" 3`"
        OPTIONS3="`str_get_arg_from "$INPUT" 4`"
        OPTIONS4="`str_get_arg_from "$INPUT" 5`"
        OPTION="`str_get_arg "$INPUT" 2`"
        OPTION1="`str_get_arg "$INPUT" 2`"
        OPTION2="`str_get_arg "$INPUT" 3`"
        OPTION3="`str_get_arg "$INPUT" 4`"
        OPTION4="`str_get_arg "$INPUT" 5`"
        OPTION5="`str_get_arg "$INPUT" 6`"
        OPTION6="`str_get_arg "$INPUT" 7`"
        OPTION7="`str_get_arg "$INPUT" 8`"
        OPTION8="`str_get_arg "$INPUT" 9`"
        OPTION9="`str_get_arg "$INPUT" 10`"
        OPTIONS_A=("$OPTION" "$OPTION2" "$OPTION3" "$OPTION4" "$OPTION5" "$OPTION6" "$OPTION7" "$OPTION8" "$OPTION9")
    fi
    if test "$TASK" = "insert" -o "$TASK" = "insert_command"
    then
        # $1 command
        # move command to options, insert new command
        OPTION9="$OPTION8"
        OPTION8="$OPTION7"
        OPTION7="$OPTION6"
        OPTION6="$OPTION5"
        OPTION5="$OPTION4"
        OPTION4="$OPTION3"
        OPTION3="$OPTION2"
        OPTION2="$OPTION1"
        OPTION1="$COMMAND"
        OPTION="$COMMAND"
        OPTIONS2="$OPTIONS"
        OPTIONS="$COMMAND $OPTIONS"
        COMMAND="$1"
    fi
    if test "$TASK" = "debug"
    then
        echo_debug_variable COMMAND OPTION OPTION2 OPTION3 OPTION4 OPTION5 OPTION6 OPTION7 OPTION8 OPTION9
    fi
}

function fill_command_options
{
    command_options fill "$@"
}

function insert_cmd
{
    command_options insert "$@"
}

function assign
{
    #unset -v "$1" || echo_error_function "Invalid variable name: $1" $ERROR_CODE_DEFAULT
    test $# = 2 -a -n "$1" && printf -v "$1" '%s' "$2" && return 0
    test $# = 1 -a -n "${1%%=*}" && printf -v "${1%%=*}" '%s' "${1#*=}" && return 0
    test $# != 1 -a $# != 2 && echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT
    echo_error_function "Empty variable name argument" $ERROR_CODE_DEFAULT
}

function function_copy
# $1 original function name
# $2 new function name with the same content
{
    local ORIGINAL=$(declare -f "$1")
    local NEW="$2${ORIGINAL#$1}"
    eval "$NEW"
}

function array_variable
{
    local LINE
    read LINE < <(declare -p "$1" 2> /dev/null) || return 1
    test_str "$LINE" "^declare -[aA]"
}

function array_assign
{
    #unset -v "$1" || echo_error_function "Invalid variable name: $1" $ERROR_CODE_DEFAULT
    test $# = 2 && eval "$1"="$2" && return 0
    test $# = 1 && eval "${1%%=*}"="${1#*=}" && return 0
    test $# != 1 -a $# != 2 && echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT
    echo_error_function "Empty variable name argument" $ERROR_CODE_DEFAULT
}

function array_assign_arguments
{
    #unset -v "$1" || echo_error_function "Invalid variable name: $1" $ERROR_CODE_DEFAULT
    test $# = 0 && echo_error_function "Empty variable name argument" $ERROR_CODE_DEFAULT
    local VAR="$1"
    shift
    local ARRAY
    local ARGUMENT
    local BACKUP_IFS="$IFS"
    IFS=''
    for ARGUMENT in "$@"
    do
        ARRAY+=($ARGUMENT)
    done
    IFS="$BACKUP_IFS"
    array_copy ARRAY "$VAR"
}

function array_copy_bad
# $1 original array name
# $2 new array name with the same content
{
    local ORIGINAL=$(declare -p "$1")
    local NEW="${ORIGINAL/declare -[aA]/}"
    local NEW="${NEW/$1=\'/$2=}"
    local NEW="${NEW%\'}"
    # error processing ' character
    echo "NEW=$NEW"
    eval "$NEW"
}

function array_copy
# $1 original array name
# $2 new array name with the same content
{
    local ORIGINAL=$(declare -p "$1")
    local NEW="${ORIGINAL/$1=/ARRAY_COPY=}"
    eval "$NEW"
    #echo "AC!=${!ARRAY_COPY[@]}"
    #echo "AC@=${ARRAY_COPY[@]}"

    for INDEX in "${!ARRAY_COPY[@]}"
    do
        #echo "INDEX=$INDEX    $2[\"$INDEX\"]=${ARRAY_COPY[$INDEX]}"
        eval "$2[\"$INDEX\"]=\"\${ARRAY_COPY[$INDEX]}\""
    done
}

#NAMESPACE/string/start
function str_trim
{
    local STR="$@"
    test -n "${!@+exist}" && STR="${!@}"
    #echo "STR=$STR"
    STR="${STR#"${STR%%[![:space:]]*}"}"   # delete leading whitespace characters
    STR="${STR%"${STR##*[![:space:]]}"}"   # delete trailing whitespace characters
    test -n "${!@+exist}" && assign "${@}" "$STR" || command echo -n "$STR"
}

function str_count_chars
# $1 [variable]
# $2 string
# $3 character to count
{
    if test $# = 3
    then
        local VAR="$1"
        local STR="$2"
        local CHR="$3"
    elif test $# = 2
    then
        local VAR=""
        local STR="$1"
        local CHR="$2"
    else
        echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT
    fi

    STR="${STR//[^$CHR]}"
    local -i CNT=${#STR}

    test -n "$VAR" && assign "$VAR" $CNT || command echo -n $CNT
    return 0
}

function str_word
# add words if not present delimited by space to string or variable
# delete words delimited by start/spaces/end from string or variable
# check word in string or variable
# $1 add/delete/check
# $2 variable or string
# $3+ word[s]
{
    local STR="$2"
    test -n "${!2+exist}" && STR="${!2}"
    local W

    case "$1" in
        add)
            for W in "${@:3}"
            do
                if ! test_str "$STR" "\b$W\b"
                then
                    test -n "$STR" && STR="$STR "
                    STR="$STR$W"
                fi
            done
            ;;
        delete)
            for W in "${@:3}"
            do
                STR="${STR% $W}"
                STR="${STR#$W }"
                STR="${STR/ $W / }"
            done
            ;;
        check)
            local -i RESULT=0
            for W in "${@:3}"
            do
                test_str "$STR" "\b$3\b"
                let RESULT=$RESULT+$?
            done
            return $RESULT
            ;;
    esac

    test -n "${!2+exist}" && assign "$2" "$STR" || command echo -n "$STR"
}

function str_array_convert
{
    if test $# = 2
    then
        local VAR="$1"
        local TMP="$2"
    elif test $# = 1
    then
        local VAR=""
        local TMP="$1"
    else
        echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT
    fi

    if test_str "$TMP" "^[(].*[)]$"
    then
        ARRAY_CONVERT="$TMP"
    elif test_str "$TMP" "^[[].*[]]$"
    then
        TMP="${TMP:1:${#TMP}-2}"
        ARRAY_CONVERT="(\"${TMP//,/\" \"}\")"
    elif test_str "$TMP" "^[{].*[}]$"
    then
        TMP="${TMP:1:${#TMP}-2}"
        ARRAY_CONVERT="(\"${TMP//:/\" \"}\")"
    else
        ARRAY_CONVERT="($TMP)"
    fi

    test -n "$VAR" && assign "$VAR=$ARRAY_CONVERT" || command echo -n "$ARRAY_CONVERT"
    return 0
}

function str_parse_url
# $1 URL
#   [path/]filename
#   host:[path/]filename
#   user@host:[path/]filename
#   protocol://user@host:[path/]filename
# $2 VAR_ARRAY       - associative array variable name to store values in
#   ${2[PROTOCOL]}
#   ${2[USER_HOST]}
#   ${2[HOST]}
#   ${2[USER]}
#   ${2[PASSWORD]}
#   ${2[FILE]}
#   ${2[LOCAL]}
{
    PARSE_URL="$1"
    PARSE_URL_PROTOCOL=""
    PARSE_URL_USER_HOST=""
    PARSE_URL_HOST=""
    PARSE_URL_USER=""
    PARSE_URL_FILE=""
    PARSE_URL_LOCAL="yes"
    if test_str --ignore-case "$PARSE_URL" "^([a-z]+):\/\/"
    then
        PARSE_URL_PROTOCOL="${BASH_REMATCH[1]}"
        PARSE_URL="${PARSE_URL#*://}"
        test "$PARSE_URL_PROTOCOL" = "file" && PARSE_URL_LOCAL="yes" || PARSE_URL_LOCAL="no"
    else
        PARSE_URL_PROTOCOL=""
        test -e "$PARSE_URL" && PARSE_URL_LOCAL="yes" || PARSE_URL_LOCAL=""
    fi
    if test_yes PARSE_URL_LOCAL
    then
        PARSE_URL_FILE="$PARSE_URL"
    elif test_str "$PARSE_URL" "^(.+)@(.+):(.+)$" # user@host:/path/file    user@host:file
    then
        test -z "$PARSE_URL_PROTOCOL" && PARSE_URL_PROTOCOL="remote"
        PARSE_URL_USER_HOST="${BASH_REMATCH[1]}@${BASH_REMATCH[2]}"
        PARSE_URL_USER="${BASH_REMATCH[1]}"
        PARSE_URL_HOST="${BASH_REMATCH[2]}"
        PARSE_URL_FILE="${BASH_REMATCH[3]}"
        PARSE_URL_LOCAL="no"
    elif test_str "$PARSE_URL" "^([^:/]+)@([^:/]+)$" # user@host
    then
        test -z "$PARSE_URL_PROTOCOL" && PARSE_URL_PROTOCOL="remote"
        PARSE_URL_USER_HOST="${BASH_REMATCH[1]}@${BASH_REMATCH[2]}"
        PARSE_URL_USER="${BASH_REMATCH[1]}"
        PARSE_URL_HOST="${BASH_REMATCH[2]}"
        PARSE_URL_FILE="${BASH_REMATCH[3]}"
        PARSE_URL_LOCAL="no"
    elif test_str "$PARSE_URL" "^(.+)@([^/]*)(/.+)$" # user@host/path/file
    then
        test -z "$PARSE_URL_PROTOCOL" && PARSE_URL_PROTOCOL="remote"
        PARSE_URL_USER_HOST="${BASH_REMATCH[1]}@${BASH_REMATCH[2]}"
        PARSE_URL_USER="${BASH_REMATCH[1]}"
        PARSE_URL_HOST="${BASH_REMATCH[2]}"
        PARSE_URL_FILE="${BASH_REMATCH[3]}"
        PARSE_URL_LOCAL="no"
    elif test_str "$PARSE_URL" "^(.+):(/.+)$" # host:/path/file
    then
        test -z "$PARSE_URL_PROTOCOL" && PARSE_URL_PROTOCOL="remote"
        PARSE_URL_USER_HOST="${BASH_REMATCH[1]}"
        PARSE_URL_HOST="${BASH_REMATCH[1]}"
        PARSE_URL_FILE="${BASH_REMATCH[2]}"
        PARSE_URL_LOCAL="no"
    elif test_str "$PARSE_URL" "^(.+):(.+)$" # host:/path/file    host:file
    then
        if test_yes PARSE_URL_PREFER_LOCAL
        then
            test -z "$PARSE_URL_PROTOCOL" && PARSE_URL_PROTOCOL="file"
            PARSE_URL_USER_HOST=""
            PARSE_URL_HOST=""
            PARSE_URL_FILE="$PARSE_URL"
            PARSE_URL_LOCAL="yes"
        else
            test -z "$PARSE_URL_PROTOCOL" && PARSE_URL_PROTOCOL="remote"
            test_str "$PARSE_URL" "^(.+):(.+)$"
            PARSE_URL_USER_HOST="${BASH_REMATCH[1]}"
            PARSE_URL_HOST="${BASH_REMATCH[1]}"
            PARSE_URL_FILE="${BASH_REMATCH[2]}"
            PARSE_URL_LOCAL="no"
        fi
    else
        PARSE_URL_FILE="$PARSE_URL"
        PARSE_URL_LOCAL="yes"
    fi
    #echo "PARSE_URL=$PARSE_URL"
    #echo "PARSE_URL_PROTOCOL=$PARSE_URL_PROTOCOL"
    #echo "PARSE_URL_USER_HOST=$PARSE_URL_USER_HOST"
    #echo "PARSE_URL_HOST=$PARSE_URL_HOST"
    #echo "PARSE_URL_USER=$PARSE_URL_USER"
    #echo "PARSE_URL_FILE=$PARSE_URL_FILE"
    if test -n "$2"
    then
        assign "$2[URL]" "$PARSE_URL"
        assign "$2[PROTOCOL]" "$PARSE_URL_PROTOCOL"
        assign "$2[USER_HOST]" "$PARSE_URL_USER_HOST"
        assign "$2[USER]" "$PARSE_URL_USER"
        assign "$2[PASSWORD]" "$PARSE_URL_PASSWORD"
        assign "$2[HOST]" "$PARSE_URL_HOST"
        assign "$2[FILE]" "$PARSE_URL_FILE"
        assign "$2[LOCAL]" "$PARSE_URL_LOCAL"
    fi
}

function str_parse_args
# $1 string with arguments and options in quotes
# !!! $2 destination array variable
{
    PARSE_ARGS=()

    #local ARRAY="${2}"
    #local EVAL="`printf '%q\n' "$1"`"
    #EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:\\(:(:g' --expression='s:\\):):g' --expression='s:\\'"'"':'"'"':g' --expression='s:\`:_:g')"
    #EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:\`:_:g')"
    #local EVAL="`echo "$1" | sed --expression='s:[(]:\\\\(:g' --expression='s:[)]:\\\\):g' --expression='s:[;]:\\\\;:g'`"
    local EVAL="$1"
    #echo_debug "$EVAL"

    eval "set -- $EVAL"
    #echo_debug "$@"
    local -i C=1
    for V in "${@}"
    do
        #assign $ARRAY "($V)"
        #eval "${!ARRAY}"+=($V)
        PARSE_ARGS+=("$V")
        export PARSE_ARGS_$C="$V"
        C=C+1
    done
}

function str_get_arg
# $1 string with ""
# $2 index
{
    local FROM="${2-1}"
    #local EVAL="`printf '%q\n' "$1"`"
    #EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:`:_:g')"
    local EVAL="$1"
    #echo_debug_variable EVAL

    eval "set -- $EVAL"
    #echo_debug_variable @
    echo "${@:$FROM:1}"
}

function str_get_arg_from
# $1 string with ""
# $2 index
{
    local FROM="${2-1}"
    #local EVAL="`printf '%q\n' "$1"`"
    #EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:`:_:g')"
    #EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\`:_:g')"
    local EVAL="$1"
    #echo_debug "$EVAL"

    eval "set -- $EVAL"
    #echo_debug "$@"
    echo "${@:$FROM}"
}

function str_get_arg_from_quoted
# $1 string with ""
# $2 index
{
    local FROM="${2-1}"
    local EVAL="$1"
    eval "set -- $EVAL"
    #echo_debug "$@"
    echo_quote "${@:$FROM}"
}

function arguments
{
    local TASK="$1"
    shift
    case "$TASK" in
        init)
            ARGUMENTS_STORE[$ARGUMENTS_STORE_I]="$ARGUMENTS_SHIFT|$ARGUMENTS_OPTION_FOUND|$ARGUMENTS_SWITCHES_FOUND"
            #declare -a ARGUMENTS_CHECK_ALL_STORE
            #array_copy ARGUMENTS_CHECK_ALL ARGUMENTS_CHECK_ALL_STORE
            #ARGUMENTS_STORE_CHECK_ALL[$ARGUMENTS_STORE_I]="`declare -p ARGUMENTS_CHECK_ALL_STORE`"
            let ARGUMENTS_STORE_I++
            ;;
        done)
            let ARGUMENTS_STORE_I--
            ARGUMENTS_SHIFT=${ARGUMENTS_STORE[$ARGUMENTS_STORE_I]%%|*}
            ARGUMENTS_OPTION_FOUND="${ARGUMENTS_STORE[$ARGUMENTS_STORE_I]#*|}"
            ARGUMENTS_OPTION_FOUND="${ARGUMENTS_OPTION_FOUND%|*}"
            ARGUMENTS_SWITCHES_FOUND="${ARGUMENTS_STORE[$ARGUMENTS_STORE_I]##*|}"
            #eval "${ARGUMENTS_STORE_CHECK_ALL[$ARGUMENTS_STORE_I]}"
            #echo s0:${ARGUMENTS_STORE_CHECK_ALL[$ARGUMENTS_STORE_I]}
            #echo s1:${ARGUMENTS_CHECK_ALL[@]}
            #echo s2:${ARGUMENTS_CHECK_ALL_STORE[@]}
            #array_copy ARGUMENTS_CHECK_ALL_STORE ARGUMENTS_CHECK_ALL
            unset ARGUMENTS_STORE[$ARGUMENTS_STORE_I]
            #unset ARGUMENTS_STORE_CHECK_ALL[$ARGUMENTS_STORE_I]
            ;;
        loop)
            ARGUMENTS_SHIFT=0
            set_no ARGUMENTS_OPTION_FOUND
            ARGUMENTS_SWITCHES_FOUND=""
            ;;
        shift|shift/all)
            if test -n "$ARGUMENTS_SWITCHES_FOUND"
            then # test for unrecognized switches
                #echo_debug_variable ARGUMENTS_SWITCHES_FOUND
                local SWITCHES_ARGUMENT="${ARGUMENTS_SWITCHES_FOUND%;*}"
                local SWITCHES_FOUND="${ARGUMENTS_SWITCHES_FOUND#*;}"
                SWITCHES_ARGUMENT_UNKNOWN="${SWITCHES_ARGUMENT//[$SWITCHES_FOUND]/}"
                test -n "$SWITCHES_ARGUMENT_UNKNOWN" -a "$TASK" = "shift" && echo_error "Unknown switches: $SWITCHES_ARGUMENT_UNKNOWN in -$SWITCHES_ARGUMENT" $ERROR_CODE_DEFAULT
                #test -n "$SWITCHES_ARGUMENT_UNKNOWN" && echo_warning "Unknown switches: $SWITCHES_ARGUMENT_UNKNOWN in -$SWITCHES_ARGUMENT"
                let ARGUMENTS_SHIFT++
            else
                SWITCHES_ARGUMENT_UNKNOWN=""
            fi
            test $ARGUMENTS_SHIFT -ne 0 && return $?
            ;;
        check)
            arguments_check "$@"
            ;;

        onestep)
            test "$1" = "run" && shift && arguments check/run "$@" || arguments check/add "$@"
            ;;
        check/add)
            ARGUMENTS_CHECK_ADD+=("`echo_quote "$@"`")
            ;;
        check/run)
            arguments init
            while test $# -gt 0
            do
                arguments loop

                local -a CHECK=()
                local CHECK_INDEX
                for CHECK_INDEX in "${!ARGUMENTS_CHECK_ADD[@]}"
                do
                    array_assign CHECK "(${ARGUMENTS_CHECK_ADD[$CHECK_INDEX]})"
                    test ${#CHECK[@]} = 3 && arguments check "${CHECK[0]}" "${CHECK[1]}" "${CHECK[2]}" "$@"
                    test ${#CHECK[@]} = 2 && arguments check "${CHECK[0]}" "${CHECK[1]}" "$@"
                    test ${#CHECK[@]} = 1 && arguments check "${CHECK[0]}" "$@"
                done

                arguments shift && shift $ARGUMENTS_SHIFT && continue
                echo_error "Unknown argument: $1" 1
            done
            arguments done
            ARGUMENTS_CHECK_ADD=()
            ;;

        check/all|oneline)
            local TYPE="$1"
            test "$TYPE" = "unknown" && test "${#ARGUMENTS_CHECK_ALL[@]}" -ne 0 && echo_error_function "Unknown argument(s): ${ARGUMENTS_CHECK_ALL[@]}" 1
            test "$TYPE" = "unknown" && return 0
            test "$TYPE" = "switch" -o "$TYPE" = "value" && local OPT1="$2" && local OPT2="$3" && shift 3
            test "$TYPE" = "option" && local OPT1="$2" && shift 2

            arguments init
            test $# -ne 0 && array_assign_arguments ARGUMENTS_CHECK_ALL "$@" #&& echo "ARGUMENTS_CHECK_ALL=${ARGUMENTS_CHECK_ALL[@]} [NEW] = $@"
            #test $# -eq 0 && echo "ARGUMENTS_CHECK_ALL=${ARGUMENTS_CHECK_ALL[@]} [OLD]"
            set -- "${ARGUMENTS_CHECK_ALL[@]}"
            ARGUMENTS_CHECK_ALL=()
            while test $# -gt 0
            do
                arguments loop
                test "$TYPE" = "switch" -o "$TYPE" = "value" && arguments check "$TYPE" "$OPT1" "$OPT2" "$@"
                test "$TYPE" = "option" && arguments check "$TYPE" "$OPT1" "$@"
                if arguments shift/all
                then # do shift if found and replace unknown switch arguments
                    shift $ARGUMENTS_SHIFT
                    test -n "$SWITCHES_ARGUMENT_UNKNOWN" && ARGUMENTS_CHECK_ALL+=("-$SWITCHES_ARGUMENT_UNKNOWN")
                    continue
                fi
                # store unknown argument for later
                ARGUMENTS_CHECK_ALL+=("$1")
                shift
            done
            arguments done
            ;;
        *)
            echo_error_function "Unknown argument: $TASK" $ERROR_CODE_DEFAULT
            ;;
    esac
}

function arguments_check
# $1 type: switch
# $2 argument name: short|long
# $3 argument store: variable[|value[|tester]]
# $4 arguments: "$@"

# $1 type: value
# $2 argument name: short|long
# $3 argument store: variable[|tester] variable|default_value|tester
# $4 arguments: "$@"

# $1 type: option
# $2 argument store: variable[|tester]
# $3 arguments: "$@"

# $1 type: tester
# $2 tester array
# $3 argument value
{
    local CHECK="$1"
    shift
    case "$CHECK" in
        switch)
            if test_str "$1" "^.*\|.*$"
            then
                local ARG_SHORT="${1%|*}"
                local ARG_LONG="${1#*|}"
            else
                local ARG_SHORT="$1"
                local ARG_LONG=""
            fi
            if test_str "$2" "^.*\|.*\|.*$"
            then
                local ARG_VAR="${2%%|*}"
                local ARG_VALUE="${2#*|}"
                local ARG_VALUE="${ARG_VALUE%|*}"
                local ARG_TEST="${2##*|}"
            elif test_str "$2" "^.*\|.*$"
            then
                local ARG_VAR="${2%|*}"
                local ARG_VALUE="${2#*|}"
                local ARG_TEST=""
            else
                local ARG_VAR="$2"
                local ARG_VALUE=""
                local ARG_TEST=""
            fi
            shift 2
            ;;
        value)
            if test_str "$1" "^.*\|.*$"
            then
                local ARG_SHORT="${1%|*}"
                local ARG_LONG="${1#*|}"
            else
                local ARG_SHORT="$1"
                local ARG_LONG=""
            fi
            if test_str "$2" "^.*\|.*\|.*$"
            then
                local ARG_VAR="${2%%|*}"
                local ARG_VALUE="${2#*|}"
                local ARG_VALUE="${ARG_VALUE%|*}"
                local ARG_TEST="${2##*|}"
            elif test_str "$2" "^.*\|.*$"
            then
                local ARG_VAR="${2%|*}"
                local ARG_VALUE=""
                local ARG_TEST="${2#*|}"
            else
                local ARG_VAR="$2"
                local ARG_VALUE=""
                local ARG_TEST=""
            fi
            shift 2
            ;;
        option)
            if test_str "$1" "^.*\|.*$"
            then
                local ARG_VAR="${1%|*}"
                local ARG_TEST="${1#*|}"
            else
                local ARG_VAR="$1"
                local ARG_TEST=""
            fi
            shift
            ;;
        tester)
            local ARG_TEST="$1"
            local ARG_OPTION="$2"
            local RESULT=0
            if test -n "$ARG_TEST"
            then
                if test_array "$ARG_TEST"
                then
                    str_array_convert ARG_TEST "$ARG_TEST"
                    ARG_TEST="${ARG_TEST:1:${#ARG_TEST}-2}"
                    #echo_debug "Possible values for test $ARG_TEST vs $ARG_OPTION"
                    str_word check ARG_TEST "$ARG_OPTION" || echo_error "Argument `echo_quote "$ARG_OPTION"` is not supported. Available: $ARG_TEST" $ERROR_CODE_DEFAULT
                else
                    shift
                    #echo_debug "Initial variable value for testers $ARG_TEST: original=\"$ARGUMENTS_VALUE_ORIGINAL\" input=\"$ARGUMENTS_VALUE\""
                    for TEST in $ARG_TEST
                    do
                        arguments_tester_$TEST "$@"
                        test_ne0 && RESULT=1 && break
                        ARGUMENTS_VALUE_ORIGINAL="$ARGUMENTS_VALUE" # new original value from testers
                    done
                    #echo_debug "Final value from testers with exit code $RESULT: output=\"$ARGUMENTS_VALUE\""
                fi
            fi
            return $RESULT
            ;;
        *)  arguments_check_$CHECK "$@"
            return $?
            ;;
    esac

    test_str "$ARG_VAR" "/" && ARGUMENTS_VALUE_ORIGINAL="" || ARGUMENTS_VALUE_ORIGINAL="${!ARG_VAR}"
    #echo ARG_VAR=$ARG_VAR ARGUMENTS_VALUE_ORIGINAL=$ARGUMENTS_VALUE_ORIGINAL

    local ARG_ASSIGN="no"
    ARGUMENTS_NAME="$1"
    ARGUMENTS_VALUE=""
    case "$CHECK" in
        switch)
            local -i ARG_FOUND_COUNT=0
            if test "$1" = "--$ARG_LONG" -o "$1" = "-$ARG_SHORT"
            then # single long or single short switch
                let ARGUMENTS_SHIFT++
                ARG_FOUND_COUNT=1
            fi
            if test -n "$ARG_SHORT" && test_str "$1" "^-[^-]" && test "${#1}" -ge 3 && test_str "$1" "$ARG_SHORT"
            then # multiple short switches
                test -z "$ARGUMENTS_SWITCHES_FOUND" && ARGUMENTS_SWITCHES_FOUND="${1:1};"
                ARGUMENTS_SWITCHES_FOUND="${ARGUMENTS_SWITCHES_FOUND}$ARG_SHORT"
                str_count_chars ARG_FOUND_COUNT "$1" "$ARG_SHORT"
            fi

            test $ARG_FOUND_COUNT = 0 && return 1
            ARGUMENTS_VALUE="$ARG_VALUE"
            local -i ARG_FOUND_COUNT_I=0
            while test $ARG_FOUND_COUNT_I -lt $ARG_FOUND_COUNT
            do
                arguments_check tester "$ARG_TEST" "$@"
                let ARG_FOUND_COUNT_I++
            done
            set_yes ARG_ASSIGN
            ;;
        value)
            if test "$1" = "--$ARG_LONG" -o "$1" = "-$ARG_SHORT"
            then
                ARGUMENTS_VALUE="$2"
                if test $# -eq 1 -o "${2:0:1}" = "-"
                then
                    test -z "$ARG_VALUE" && echo_error "Missing value for argument \"$1\"" $ERROR_CODE_DEFAULT
                    ARGUMENTS_VALUE="$ARG_VALUE"
                fi
                shift && arguments_check tester "$ARG_TEST" "$@" && set_yes ARG_ASSIGN && let ARGUMENTS_SHIFT+=2
            fi

            if test "${1%%=*}" = "--$ARG_LONG"
            then
                ARGUMENTS_VALUE="${1#*=}"
                shift && arguments_check tester "$ARG_TEST" "$ARGUMENTS_VALUE" "$@" && set_yes ARG_ASSIGN && let ARGUMENTS_SHIFT++
            fi
            ;;
        option)
            test_yes ARGUMENTS_OPTION_FOUND && return 1
            test "${1:0:1}" = "-" && return 1
            test -n "$ARGUMENTS_VALUE_ORIGINAL" && return 1
            ARGUMENTS_VALUE="$1"
            arguments_check tester "$ARG_TEST" "$@" && set_yes ARG_ASSIGN ARGUMENTS_OPTION_FOUND && let ARGUMENTS_SHIFT++
            ;;
    esac

    if test_yes ARG_ASSIGN
    then
        test -z "$ARG_VAR" && return 0
        if test_str "$ARG_VAR" "/append"
        then
            ARG_VAR="${ARG_VAR%/*}"
            #echo "assign \"$ARG_VAR\" \"$ARGUMENTS_VALUE\""
            test -z "${!ARG_VAR}" && assign "$ARG_VAR" "$ARGUMENTS_VALUE" || assign "$ARG_VAR" "${!ARG_VAR}$ARGUMENTS_VALUE_DELIMITER$ARGUMENTS_VALUE"
        elif test_str "$ARG_VAR" "/array"
        then
            ARG_VAR="${ARG_VAR%/*}"
            #echo "$ARG_VAR+=(\"$ARGUMENTS_VALUE\")"
            eval "$ARG_VAR+=(\"$ARGUMENTS_VALUE\")"
        else
            assign "$ARG_VAR" "$ARGUMENTS_VALUE"
        fi
        return 0
    fi
    return 1
}

function arguments_check_info
{
    echo_debug INFO "Argument check for type info: $1"
}

function arguments_tester_info
{
    echo_debug INFO "Argument tester for string: $1"
}

function arguments_tester_file
{
    test -f "$1" || echo_error "Specified file: `echo_quote "$1"` doesn't exist" $ERROR_CODE_DEFAULT
}

function arguments_tester_file_exist
{
    test -f "$1" || echo_error "Specified file: `echo_quote "$1"` doesn't exist" $ERROR_CODE_DEFAULT
}

function arguments_tester_file_read
{
    test -r "$1" || echo_error "Specified file: `echo_quote "$1"` can't be readed" $ERROR_CODE_DEFAULT
}

function arguments_tester_file_write
{
    test -w "$1" || echo_error "Specified file: `echo_quote "$1"` can't be written" $ERROR_CODE_DEFAULT
}

function arguments_tester_file_canonicalize
{
    ARGUMENTS_VALUE="`readlink --canonicalize "$ARGUMENTS_VALUE"`"
}

function arguments_tester_ping
{
    check_ping "$1" || echo_error "Specified host: `echo_quote "$1"` is not reachable, ping problem" $ERROR_CODE_DEFAULT
}

function arguments_tester_increase
{
    test -n "$ARGUMENTS_VALUE_ORIGINAL" && ARGUMENTS_VALUE="$ARGUMENTS_VALUE_ORIGINAL" # reuse already assigned value - do not use switch value
    test_integer "$ARGUMENTS_VALUE" || echo_error "Argument value: `echo_quote "$ARGUMENTS_VALUE_NEW"` is not integer" $ERROR_CODE_DEFAULT

    local -i ARGUMENTS_VALUE_INTEGER=$ARGUMENTS_VALUE
    let ARGUMENTS_VALUE_INTEGER++ # increase value in local integer variable
    ARGUMENTS_VALUE=$ARGUMENTS_VALUE_INTEGER
}

function arguments_tester_yes_no
{
    test_yes ARGUMENTS_VALUE && return 0
    test_no ARGUMENTS_VALUE && return 0
    echo_error "Argument value: `echo_quote "$ARGUMENTS_VALUE"` in \"$ARGUMENTS_NAME\" need to be \"yes\" or \"no\"" $ERROR_CODE_DEFAULT
}

function arguments_tester_empty_yes
{
    echo "ARGUMENTS_VALUE=$ARGUMENTS_VALUE"
    test -z "$ARGUMENTS_VALUE" && ARGUMENTS_VALUE="yes"
    return 0
}
#NAMESPACE/string/end

#NAMESPACE/file/start
function file_find
# $1 mask|path [with mask]
# $2 [array to store file names]
{
    if test -z "$1"
    then
        local FIND_DIR="."
        local FIND_MASK="*"
    elif test -d "$1"
    then
        local FIND_DIR="$1"
        local FIND_MASK="*"
    else
        local FIND_DIR="`dirname "$1"`"
        local FIND_MASK="`basename "$1"`"
    fi

    #echo_debug_variable FIND_DIR FIND_MASK

    #local -a FILES=()
    FILE_FIND=()
    local FILE
    while read -r -d $'\0' FILE
    do
        FILE_FIND+=("$FILE")
    done < <(find "$FIND_DIR" -maxdepth 1 -type f -iname "$FIND_MASK" -printf "%f\0" | sort --zero-terminated)

    test -n "$2" && array_copy FILE_FIND "$2"
}

function file_loop
# $1 mask|path [with mask]
# $@ commands with \$FILE variable
{
    local -a FILE_LOOP

    file_find "$1" FILE_LOOP
    shift

    local FILE_LOOP_CMD
    test $# -eq 0 && FILE_LOOP_CMD="`cat`"

    # count: echo ${!FILE_LOOP[*]}
    local FILE
    for FILE in ${FILE_LOOP[@]}
    do
        test $# -eq 0 && eval "$FILE_LOOP_CMD" || eval "$@"
    done
}

function file_temporary_name
# $1 temporary file postfix
# $2 source filename to be use as part of temporary filename
{
    test -n "$2" && echo "/tmp/`basename "$2"`.$1.$$.tmp" || echo "/tmp/tools.$1.$$.tmp"
}

function file_delete
{
    if test -f "$1"
    then
        $RM "$1"
        test ! -f "$1" || echo_error_function "Can't delete `echo_quote "$1"` file" $ERROR_CODE_DEFAULT
    else
        return 0
    fi
}

function file_prepare_move
{
    local F="$1"
    local -i N=$2
    local -i C=$3
    local -i N1
    let N1=N+1

    test $N1 -ne $C -a -f "$F-$N" -a -f "$F-$N1" && file_prepare_move "$1" $N1 $C
    file_delete "$F-$N1"
    mv "$F-$N" "$F-$N1"
}

function file_prepare
{
    local FILE=""
    local EMPTY="no"
    local ROLL="no"
    local COUNT="9"
    local USER=""
    local GROUP=""
    arguments init
    while test $# -gt 0
    do
        arguments loop
        arguments check switch "e|empty" "EMPTY|yes" "$@"
        arguments check switch "r|roll" "ROLL|yes" "$@"
        arguments check value "c|count" "COUNT" "$@"
        arguments check switch "u|user" "USER|" "$@"
        arguments check switch "g|group" "GROUP|" "$@"
        arguments check option "FILE" "$@"
        arguments shift && shift $ARGUMENTS_SHIFT && continue
        echo_error_function "Unknown argument: $1" $ERROR_CODE_DEFAULT
    done
    arguments done
    test -z "$FILE" && echo_error_function "Filename is not specified" $ERROR_CODE_DEFAULT

    if test_yes "$ROLL" && test -f "$FILE"
    then
        test -f "$FILE-1" && file_prepare_move "$FILE" 1 "$COUNT"
        mv "$FILE" "$FILE-1"
    fi

    #test_yes "$EMPTY" && file_delete "$FILE"

    if test ! -w "$FILE"
    then
        mkdir -p "`dirname $FILE`"
        touch "$FILE"
        chmod ug+w "$FILE" 2> /dev/null
    fi
    test -w "$FILE" || echo_error_function "Can't create and prepare file for writting: `echo_quote "$FILE"`" $ERROR_CODE_DEFAULT

    test_yes "$EMPTY" && cat /dev/null > "$FILE"

    test -n "$USER" && chgrp "$USER" "$FILE" 2> /dev/null
    test -n "$GROUP" && chown "$GROUP" "$FILE" 2> /dev/null

    return 0
}

function file_remote
# $1 get
# $2 url with remote file
# $3 local file
#
# $1 put
# $2 url with remote file
# $3 local file
{
    local TASK="$1"
    local -A URL
    str_parse_url "$2" URL
    test -n "$3" && FILE_REMOTE="$3" || FILE_REMOTE="`file_temporary_name file_remote "${URL[FILE]}"`"

    case "$TASK" in
        get)
            file_delete "$FILE_REMOTE"
            if test_str "${URL[PROTOCOL]}" "^(ssh|scp|remote)$"
            then
                $SCPq "${URL[HOST]}":"${URL[FILE]}" "$FILE_REMOTE" || return 1
            elif test_yes "${URL[LOCAL]}"
            then
                cp -p "${URL[FILE]}" "$FILE_REMOTE" || return 1
            else
                echo_error_function "Unknown transfer protocol for `echo_quote "$URL"`" $ERROR_CODE_DEFAULT
            fi
            ;;
        put)
            if test_str "${URL[PROTOCOL]}" "^(ssh|scp|remote)$"
            then
                $SCPq "$FILE_REMOTE" "${URL[HOST]}":"${URL[FILE]}" || return 1
            elif test_yes "${URL[LOCAL]}"
            then
                cp -p "$FILE_REMOTE" "${URL[FILE]}" || return 1
            else
                echo_error_function "Unknown transfer protocol for `echo_quote "$URL"`" $ERROR_CODE_DEFAULT
            fi
            file_delete "$FILE_REMOTE"
            ;;
    esac
}

function file_line_delete_local
# $1 filename
# $2 delete regexp
{
    local FILE="$1"
    local TEMP_FILE="`file_temporary_name file_line_delete_local "$FILE"`"
    local REGEXP="$2"
    local ERROR_MSG="Delete line \"$REGEXP\" from file `echo_quote "$FILE"` fail"
    if test -r "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        if diff "$FILE" "$TEMP_FILE" > /dev/null 2> /dev/null
        then
            $GREP --invert-match --extended-regexp "$REGEXP" "$TEMP_FILE" > "$FILE" 2> /dev/null
            file_delete "$TEMP_FILE"
        else
            file_delete "$TEMP_FILE"
            echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        fi
    fi
}

function file_line_add_local
# $1 filename
# $2 add this line
# $3 add after this regexp line (or if not found put at end of file)
# $4 replace this line (or if not found add after $3)
{
    local FILE="$1"
    local TEMP_FILE="`file_temporary_name file_line_add_local "$FILE"`"
    local LINE="$2"
    local REGEXP_AFTER="$3"
    local REGEXP_REPLACE="$4"
    local ERROR_MSG="Add line \"$LINE\" to file `echo_quote "$FILE"` fail"

    test -e "$FILE" || touch "$FILE"

    if test -z "$REGEXP_AFTER$REGEXP_REPLACE"
    then
        command echo "$LINE" >> "$FILE" || echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
    else
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        if test -n "$REGEXP_REPLACE" && `cat "$TEMP_FILE" | $AWK 'BEGIN { f=1; } /'"$REGEXP_REPLACE"'/ { f=0; } END { exit f; }'`
        then
            $AWK --assign=line="$LINE" 'BEGIN { p=0; gsub(/\n/, "\\n", line); } p==0&&/'"$REGEXP_REPLACE"'/ { p=1; print line; next } { print; } END { if (p==0) print line; }' "$TEMP_FILE" > "$FILE"
        elif test -n "$REGEXP_AFTER" && `cat "$TEMP_FILE" | $AWK 'BEGIN { f=1; } /'"$REGEXP_AFTER"'/ { f=0; } END { exit f; }'`
        then
            $AWK --assign=line="$LINE" 'BEGIN { p=0; gsub(/\n/, "\\n", line); } p==0&&/'"$REGEXP_AFTER"'/ { print $0; p=1; print line; next } { print; } END { if (p==0) print line; }' "$TEMP_FILE" > "$FILE"
        else
            $AWK --assign=line="$LINE" 'BEGIN { gsub(/\n/, "\\n", line); } { print; } END { print line; }' "$TEMP_FILE" > "$FILE"
        fi
        if test -s "$FILE"
        then
            file_delete "$TEMP_FILE"
        else
            cat "$TEMP_FILE" > "$FILE"
            file_delete "$TEMP_FILE"
            echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        fi
    fi
}

function file_line_set_local
# $1 filename
# $2 add this line (and check before if there is not present)
# $3 add after this regexp line (or if not found put at end of file)
# $4 replace this line (or if not found add after $3)
{
    local FILE="$1"
    local LINE="$2"
    local REGEXP_AFTER="$3"
    local REGEXP_REPLACE="$4"

    if ! $GREP --quiet --line-regexp --fixed-strings -- "$LINE" "$FILE"
    then
        file_line_add_local "$FILE" "$LINE" "$REGEXP_AFTER" "$REGEXP_REPLACE"
        return 1
    else
        return 0
    fi
}

function file_line
# $1 task - add / delete / set
# $2 can be [[user@]host:][path/]filename
# $* as for file_line_*_local function
{
    local TASK="$1"
    test_str "$TASK" "(delete|add|set)" || echo_error_function "Unsupported function: $TASK. Supported: delete add set" $ERROR_CODE_DEFAULT
    local -A URL
    str_parse_url "$2" URL
    shift 2
    if test_yes "${URL[LOCAL]}" || is_localhost "${URL[HOST]}"
    then
        file_line_${TASK}_local "${URL[FILE]}" "$@"
    else
        file_remote get "${URL[URL]}" || echo_error_function "Can't retrieve `echo_quote "${URL[FILE]}"` file from ${URL[USER_HOST]}" $ERROR_CODE_DEFAULT
        #ls -la "$FILE_REMOTE"
        file_line_${TASK}_local "$FILE_REMOTE" "$@"
        #ls -la "$FILE_REMOTE"
        file_remote put "${URL[URL]}" || echo_error_function "Can't upload `echo_quote "$FILE_REMOTE"` file to ${URL[USER_HOST]}" $ERROR_CODE_DEFAULT
    fi
}

function file_replace
# $1 filename
# $* pipe_replace arguments
{
    local FILE="$1"
    local TEMP_FILE="`file_temporary_name file_replace "$FILE"`"
    local ERROR_MSG="File `echo_quote "$FILE"` string replace fail"
    shift
    if test -w "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG, temporary file create `echo_quote "$TEMP_FILE"` problem" $ERROR_CODE_DEFAULT
        cat "$TEMP_FILE" | pipe_replace "$@" > "$FILE" || echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        file_delete "$TEMP_FILE"
    else
        echo_error_function "$ERROR_MSG, file not writable" $ERROR_CODE_DEFAULT
    fi
}

function file_config
# $1 format
# $2 filename
#
# read and output value from option
# -n|--noeval - do not evaluate readed value
# $1 get
# $2 filename
# $3 option
# $4 default value
#
# read and store value into option variable: PREFIX_OPTION=VALUE and PREFIX_SECTION_OPTION=VALUE
# $1 read
# $2 filename
# $3 option
# $4 default value
#
# read and store all values into variables: PREFIX_OPTION=VALUE and PREFIX_SECTION_OPTION=VALUE
#                        or into array: ARRAY[OPTION]=VALUE and ARRAY[SECTION_OPTION]=VALUE
# $1 load
# $* --to-array <ARRAY>
# $* --to-variables
# $2 filename
#
# $1 set
# $2 filename
# $3 option
# $4 new value
{
    local TASK="$1"
    shift
    local FILE
    local SECTION_OPTION
    local SECTION
    local OPTION
    local VALUE
    local DO_EVAL="yes"
    case "$TASK" in
        format)
            local FORMAT="standard"
            test -e "$FILE" && $GREP "^[\t ]\[" "$FILE" && FORMAT="extended"
            echo "$FORMAT"
            return 0
            ;;
        get|read|set)
            arguments onestep switch "e|eval" "DO_EVAL|yes"
            arguments onestep switch "n|no-eval" "DO_EVAL|no"
            arguments onestep option "FILE|file_read"
            arguments onestep option "SECTION_OPTION"
            arguments onestep option "VALUE"
            arguments onestep run "$@"
            SECTION="`dirname "$SECTION_OPTION"`"
            OPTION="`basename "$SECTION_OPTION"`"
            ;;
        load)
            local TO_VARIABLES="no"
            local TO_ARRAY=""
            arguments onestep switch "v|to-variables" "TO_VARIABLES|yes"
            arguments onestep value "a|to-array" "TO_ARRAY"
            arguments onestep option "FILE|file_read"
            arguments onestep run "$@"
            ;;
        *)
            echo_error_function "Unknown config file task: $@" $ERROR_CODE_DEFAULT
    esac
    case "$TASK" in
        get)
            #A="  A = \"\$USER \" "; echo "-$A-"; B="`echo "$A" | awk '/^[\t ]*A[\t ]*=[\t ]*/ { sub(/^[\t ]*A[\t ]*=[\t ]*/, ""); sub(/^["]/, ""); sub(/["]*[\t ]*$/, ""); print; }'`"; eval "set O=\"$B\""; echo "-$B-$O-"
            VALUE="`$AWK 'BEGIN { if ("'"$SECTION"'" == ".") s=1; else s=0; }
                /* { print "LINE=" $0; } */
                "'"$SECTION"'" != "." && /^[\t ]*\[.*\][\t ]*$/ {
                    s=0; }
                "'"$SECTION"'" != "." && /^[\t ]*\['"$SECTION"'\][\t ]*$/ {
                    s=1; next; }
                s==1 && /^[\t ]*'"$OPTION"'[\t ]*=[\t ]*/ {
                    sub(/^[\t ]*'"$OPTION"'[\t ]*=[\t ]*/, ""); sub(/^["]/, ""); sub(/["][\t ]*$/, ""); print; }' "$FILE"`"
            test_yes DO_EVAL && eval "command echo \"$VALUE\"" || command echo "$VALUE"
            ;;
        read)
            VALUE="`file_config get "$@"`"
            test "$SECTION" != "." && assign "$FILE_CONFIG_PREFIX${SECTION}_${OPTION}" "$VALUE"
            assign "$FILE_CONFIG_PREFIX$OPTION" "$VALUE"
            ;;
        load)
            local VARIABLE
            local VALUE
            local LINE
            echo TO_ARRAY=$TO_ARRAY
            test_no TO_VARIABLES && test -z "$TO_ARRAY" && TO_ARRAY="CONFIG"
            while read LINE
            do
                #echo "LINE: $LINE"
                local VARIABLE="${LINE%%=*}"
                local VALUE="${LINE#*=}"
                test_yes TO_VARIABLES && eval "$FILE_CONFIG_PREFIX$LINE"
                test -n "$TO_ARRAY" && eval "$TO_ARRAY[$VARIABLE]=$VALUE"
            done < <( $AWK 'BEGIN { s=""; }
                    /^[\t ]*#/ { next; }
                    /^[\t ]*$/ { next; }
                    /^[\t ]*\[.*\][\t ]*$/ {
                        sub(/^.*\[/, "");
                        sub(/\].*$/, "");
                        sub(/^[\t ]*/, "");
                        sub(/[\t ]*$/, "");
                        s=$0; next; }
                    { sub(/^[\t ]*/, "");
                      sub(/[\t ]*=[\t ]*/, "=");
                      sub(/[\t ]*$/, "");
                      n=substr($0, 1, index($0, "=") - 1);
                      v=substr($0, index($0, "=") + 1);
                      if (a[n] != "") a[n]=a[n] "\"$S_NEWLINE\"";
                      if (a[s "_" n] != "") a[s "_" n]=a[s "_" n] "";
                      a[n]=a[n] v;
                      a[s "_" n]=a[s "_" n] v;
                    }
                    END { for (i in a) print i "=" a[i]; }' "$FILE")
            ;;
        set)
            local TEMP_FILE="`file_temporary_name file_config_set "$FILE"`"
            local ERROR_MSG="Configuration \"$OPTION=\"$VALUE\"\" change to file `echo_quote "$FILE"` fail"
            if test -e "$FILE"
            then
                cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG, temporary file create `echo_quote "$TEMP_FILE"` problem" $ERROR_CODE_DEFAULT
                test -w "$FILE" || echo_error_function "$ERROR_MSG, file not writable" $ERROR_CODE_DEFAULT
                $AWK 'BEGIN { opt_val="'"$OPTION"'=\"'"$VALUE"'\""; found=0; s=0; }
                    "'"$SECTION"'" != "." && /^[\t ]*\[.*\][\t ]*$/ {
                        s=0; }
                    "'"$SECTION"'" != "." && /^[\t ]*\['"$SECTION"'\][\t ]*$/ {
                        s=1; }
                    s==1 && /^[\t ]*'$OPTION'[\t ]*=[\t ]*/ {
                        print opt_val; found=1; next; }
                    { print; }
                    END { if (found == 0) { if ("'"$SECTION"'" != "." ) print "['"$SECTION"']"; print opt_val; } }' "$TEMP_FILE" > "$FILE"
                if test -s "$FILE"
                then
                    file_delete "$TEMP_FILE"
                else
                    cat "$TEMP_FILE" > "$FILE"
                    file_delete "$TEMP_FILE"
                    echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
                fi
            else
                if test "$SECTION" = "."
                then
                    echo "$OPTION=\"$VALUE\"" > "$FILE" || echo_error_function "$ERROR_MSG, file create problem" $ERROR_CODE_DEFAULT
                else
                    echo "[$SECTION]" > "$FILE" || echo_error_function "$ERROR_MSG, file create problem" $ERROR_CODE_DEFAULT
                    echo "$OPTION=\"$VALUE\"" >> "$FILE"
                fi
            fi
            ;;
    esac
}
#NAMESPACE/file/end

#NAMESPACE/network/start
function check_ssh
# $1 [user@]hostname
# $2 check via local username
{
    if test -z "$2"
    then
        $SSHbq "$1" "exit" 2> /dev/null
    else
        su - "$2" "$SSHbq \"$1\" \"exit\" 2> /dev/null"
    fi
    return $?
}

function check_internet
{
    curl --output /dev/null --silent "www.centos.org"
    return $?
}

function check_ping
{
    ping -c 1 -W 1 "$1" > /dev/null 2>&1
    return $?
}

function get_ip_arp
{
    local GET_IP_ARP="`arp "$1" 2> /dev/null | $AWK 'BEGIN { FS="[()]"; } { print $2; }'`"
    if test "$UNIX_TYPE" = "Linux" -a -z "$GET_IP_ARP"
    then
        GET_IP_ARP="`arp -n "$1" 2> /dev/null | $AWK '/ether/ { print $1; }'`"
    fi
    command echo "$GET_IP_ARP"
}

function get_ip_ping
{
    test "$UNIX_TYPE" = "SunOS" && ping -s "$1" 1 1 | $GREP "bytes from" | $AWK 'BEGIN { FS="[()]"; } { print $2; }'
    test "$UNIX_TYPE" = "Linux" && ping -q -c 1 -t 1 -W 1 "$1" 2> /dev/null | $GREP PING | $AWK 'BEGIN { FS="[()]"; } { print $2; }'
}

function get_ip
{
    local HOST="$1"
    test -z "$HOST" && HOST="`hostname`"

    local GET_IP="`get_ip_arp "$HOST"`"
    test -z "$GET_IP" && GET_IP="`get_ip_ping "$HOST"`"
    command echo "$GET_IP"
}

function is_localhost
{
    # simple basic test
    test -z "$1" -o "$1" = "localhost" -o "$1" = "127.0.0.1" && return 0

    # name test
    local UNAME_N="`uname -n`"
    #echo_debug_variable UNAME_N
    test "$1" = "$UNAME_N" && return 0

    # IP test
    local UNAME_IP="`get_ip "$UNAME_N"`"
    local REMOTE_IP="`get_ip "$1"`"
    #echo_debug_variable UNAME_IP REMOTE_IP
    test "$REMOTE_IP" = "$UNAME_IP" && return 0

    return 1
}

function get_id
{
    id | $AWK 'BEGIN { FS="[()]"; } { print $2; }'
}

function ssh_scanid
# $1 @user scan to user
# $2 scan hosts
# ssh_scanid @root host `get_ip host`
{
    local SCAN_HOSTS=""
    local SCAN_HOST=""
    local SCAN_USER=""
    local SCAN_USER_HOME=""
    local SCAN_USER_HOME_SSH=""
    local SCAN_USER_HOME_SSH_HOSTS=""
    local PARAM
    for PARAM in "$@"
    do
        test "${PARAM:0:1}" = "@" && SCAN_USER="${PARAM:1}" && continue
        SCAN_HOSTS="$SCAN_HOSTS $PARAM"
    done
    SCAN_HOSTS="${SCAN_HOSTS:1}"

    test -z "$SCAN_USER" && SCAN_USER_HOME=~ || SCAN_USER_HOME="`eval echo "~$SCAN_USER"`"
    SCAN_USER_HOME_SSH="$SCAN_USER_HOME/.ssh"
    SCAN_USER_HOME_SSH_HOSTS="$SCAN_USER_HOME/.ssh/known_hosts"

    test -d $SCAN_USER_HOME_SSH || mkdir $SCAN_USER_HOME_SSH
    chown --reference=$SCAN_USER_HOME $SCAN_USER_HOME_SSH
    touch $SCAN_USER_HOME_SSH_HOSTS
    chown --reference=$SCAN_USER_HOME $SCAN_USER_HOME_SSH_HOSTS

    echo_debug INFO "Scan host ids $SCAN_HOSTS to $SCAN_USER_HOME_SSH_HOSTS"
    for SCAN_HOST in $SCAN_HOSTS
    do
        ssh-keyscan $SCAN_HOST >> "$SCAN_USER_HOME_SSH_HOSTS" 2> /dev/null
    done
    cp "$SCAN_USER_HOME_SSH_HOSTS" "${SCAN_USER_HOME_SSH_HOSTS}_orig"
    cat "${SCAN_USER_HOME_SSH_HOSTS}_orig" | sort -u > "$SCAN_USER_HOME_SSH_HOSTS"
    file_delete "${SCAN_USER_HOME_SSH_HOSTS}_orig"
}

function ssh_scanremoteid
# ssh_scanremoteid %root              user@local@host
#                  ^ use key from     ^^^ connect to host with user, scan to local user
{
    local USEID_USER=""
    local USEID_FILE=""
    local DESTINATIONS=""
    local PARAM
    for PARAM in "$@"
    do
        test "${PARAM:0:1}" = "%" && USEID_USER="${PARAM:1}" && continue
        DESTINATIONS="$DESTINATIONS $PARAM"
    done
    DESTINATIONS="${DESTINATIONS:1}"

    test -z "$USEID_USER" && USEID_HOME=~/".ssh" || USEID_HOME="`eval echo "~$USEID_USER/.ssh"`"
    for TEST_FILE in "$USEID_HOME/id_rsa" "$USEID_HOME/id_dsa"
    do
        test -f "$TEST_FILE" && USEID_FILE="$TEST_FILE" && break
    done
    test -z "$USEID_FILE" && return 2

    local DESTINATION
    for DESTINATION in $DESTINATIONS
    do
        local DEST_HOST="${DESTINATION##*@}"
        local DEST_USER="${DESTINATION%@*}"
        local DEST_LOCAL_USER="${DESTINATION%@*}"
        local DEST_USER="${DEST_USER%@*}"
        local DEST_LOCAL_USER="${DEST_LOCAL_USER#*@}"
        echo_debug INFO "Use $USEID_FILE and scan via $DEST_USER @ $DEST_HOST to user $DEST_LOCAL_USER"
        $SSH -i $USEID_FILE $DEST_USER@$DEST_HOST "
            umask 077
            DEST_HOME=~$DEST_LOCAL_USER
            DEST_HOME_SSH=~$DEST_LOCAL_USER/.ssh
            DEST_HOME_SSH_HOSTS=~$DEST_LOCAL_USER/.ssh/known_hosts
            test -d \$DEST_HOME_SSH || mkdir \$DEST_HOME_SSH
            chown --reference=\$DEST_HOME \$DEST_HOME_SSH
            touch \$DEST_HOME_SSH_HOSTS
            chown --reference=\$DEST_HOME \$DEST_HOME_SSH_HOSTS
            ssh-keyscan `hostname` >> \$DEST_HOME_SSH_HOSTS 2> /dev/null
            ssh-keyscan `hostname --fqdn` >> \$DEST_HOME_SSH_HOSTS 2> /dev/null
            ssh-keyscan `hostname --short` >> \$DEST_HOME_SSH_HOSTS 2> /dev/null
            ssh-keyscan `get_ip` >> \$DEST_HOME_SSH_HOSTS 2> /dev/null
            test -x /sbin/restorecon && /sbin/restorecon \$DEST_HOME_SSH \$DEST_HOME_SSH_HOSTS >/dev/null 2>&1 || true
            cp \$DEST_HOME_SSH_HOSTS \${DEST_HOME_SSH_HOSTS}_orig
            cat \${DEST_HOME_SSH_HOSTS}_orig | sort -u > \$DEST_HOME_SSH_HOSTS
            rm -f \${DEST_HOME_SSH_HOSTS}_orig
            " || return 1
    done
}

function ssh_exportid
# ssh_exportid %root              @nmsadm             user@local@host
#              ^ use key from     ^^ copy key from    ^^^ connect to host with user, copy to local user
{
    local USEID_USER=""
    local USEID_FILE=""
    local COPYID_USER=""
    local COPYID_FILE=""
    local DESTINATIONS=""
    local PARAM
    for PARAM in "$@"
    do
        test "${PARAM:0:1}" = "%" && USEID_USER="${PARAM:1}" && continue
        test "${PARAM:0:1}" = "@" && COPYID_USER="${PARAM:1}" && continue
        DESTINATIONS="$DESTINATIONS $PARAM"
    done
    DESTINATIONS="${DESTINATIONS:1}"

    test -z "$COPYID_USER" && COPYID_HOME=~/".ssh" || COPYID_HOME="`eval echo "~$COPYID_USER/.ssh"`"
    for TEST_FILE in "$COPYID_HOME/id_rsa" "$COPYID_HOME/id_dsa"
    do
        test -f "$TEST_FILE" && COPYID_FILE="$TEST_FILE" && break
    done
    test -z "$COPYID_FILE" && return 2

    test -z "$USEID_USER" && USEID_HOME=~/".ssh" || USEID_HOME="`eval echo "~$USEID_USER/.ssh"`"
    for TEST_FILE in "$USEID_HOME/id_rsa" "$USEID_HOME/id_dsa"
    do
        test -f "$TEST_FILE" && USEID_FILE="$TEST_FILE" && break
    done
    test -z "$USEID_FILE" && return 2

    local DESTINATION
    for DESTINATION in $DESTINATIONS
    do
        local DEST_HOST="${DESTINATION##*@}"
        local DEST_USER="${DESTINATION%@*}"
        local DEST_LOCAL_USER="${DESTINATION%@*}"
        local DEST_USER="${DEST_USER%@*}"
        local DEST_LOCAL_USER="${DEST_LOCAL_USER#*@}"
        echo_debug INFO "Use $USEID_FILE and copy ${COPYID_FILE}.pub via $DEST_USER @ $DEST_HOST to user $DEST_LOCAL_USER"
        cat "${COPYID_FILE}.pub" | $SSH -i $USEID_FILE $DEST_USER@$DEST_HOST "
            umask 077
            DEST_HOME=~$DEST_LOCAL_USER
            DEST_HOME_SSH=~$DEST_LOCAL_USER/.ssh
            DEST_HOME_SSH_KEYS=~$DEST_LOCAL_USER/.ssh/authorized_keys
            test -d \$DEST_HOME_SSH || mkdir \$DEST_HOME_SSH
            chown --reference=\$DEST_HOME \$DEST_HOME_SSH
            touch \$DEST_HOME_SSH_KEYS
            chown --reference=\$DEST_HOME \$DEST_HOME_SSH_KEYS
            cat >> \$DEST_HOME_SSH_KEYS
            test -x /sbin/restorecon && /sbin/restorecon \$DEST_HOME_SSH \$DEST_HOME_SSH_KEYS >/dev/null 2>&1 || true
            cp \$DEST_HOME_SSH_KEYS \${DEST_HOME_SSH_KEYS}_orig
            cat \${DEST_HOME_SSH_KEYS}_orig | sort -u > \$DEST_HOME_SSH_KEYS
            rm -f \${DEST_HOME_SSH_KEYS}_orig
            " || return 1
    done
}

function ssh_importid
# ssh_importid %root              @nmsadm             user@local@host
#              ^ use key from     ^^ copy key to      ^^^ connect to host with user, copy from local user
#    "ssh_importid %current @current user@user@host" is equal to "ssh_importid user@host"
{
    local USEID_USER=""
    local USEID_FILE=""
    local COPYID_USER=""
    local COPYID_FILE=""
    local DESTINATIONS=""
    local PARAM
    for PARAM in "$@"
    do
        test "${PARAM:0:1}" = "%" && USEID_USER="${PARAM:1}" && continue
        test "${PARAM:0:1}" = "@" && COPYID_USER="${PARAM:1}" && continue
        DESTINATIONS="$DESTINATIONS $PARAM"
    done
    DESTINATIONS="${DESTINATIONS:1}"

    test -z "$USEID_USER" && USEID_HOME=~/".ssh" || USEID_HOME="`eval echo "~$USEID_USER/.ssh"`"
    for TEST_FILE in "$USEID_HOME/id_rsa" "$USEID_HOME/id_dsa"
    do
        test -f "$TEST_FILE" && USEID_FILE="$TEST_FILE" && break
    done
    test -z "$USEID_FILE" && return 2

    local DESTINATION
    for DESTINATION in $DESTINATIONS
    do
        local DEST_HOST="${DESTINATION##*@}"
        local DEST_USER="${DESTINATION%@*}"
        local DEST_USER="${DEST_USER%@*}"
        local DEST_LOCAL_USER="${DESTINATION%@*}"
        local DEST_LOCAL_USER="${DEST_LOCAL_USER#*@}"
        local DESTID_FILE=""

        test -z "$COPYID_USER" && COPYID_USER="`whoami`" && COPYID_HOME=~ || COPYID_HOME="`eval echo "~$COPYID_USER"`"
        COPYID_HOME_SSH="$COPYID_HOME/.ssh"
        COPYID_HOME_SSH_KEYS="$COPYID_HOME_SSH/authorized_keys"

        test -z "$DEST_LOCAL_USER" && DEST_HOME="~" || DEST_HOME="~$DEST_LOCAL_USER"
        DEST_HOME_SSH="$DEST_HOME/.ssh"

        test -d $COPYID_HOME_SSH || mkdir $COPYID_HOME_SSH
        chown --reference=$COPYID_HOME $COPYID_HOME_SSH
        touch $COPYID_HOME_SSH_KEYS
        chown --reference=$COPYID_HOME $COPYID_HOME_SSH_KEYS

        echo_debug INFO "Use $USEID_FILE and copy id via $DEST_USER @ $DEST_HOST from user $DEST_LOCAL_USER to $COPYID_USER"

        for TEST_FILE in "$DEST_HOME_SSH/id_rsa.pub" "$DEST_HOME_SSH/id_dsa.pub"
        do
            $SSH -i $USEID_FILE $DEST_USER@$DEST_HOST "test -f $TEST_FILE"
            test $? -eq 0 && DESTID_FILE="$TEST_FILE" && break
        done
        test -z "$DESTID_FILE" && return 2

        $SCP -i $USEID_FILE $DEST_USER@$DEST_HOST:$DESTID_FILE $COPYID_HOME_SSH/id_import.pub > /dev/null 2>&1
        if test $? -eq 0
        then
            cat $COPYID_HOME_SSH/id_import.pub >> $COPYID_HOME_SSH_KEYS
            file_delete $COPYID_HOME_SSH/id_import.pub
            cp $COPYID_HOME_SSH_KEYS ${COPYID_HOME_SSH_KEYS}_orig
            cat ${COPYID_HOME_SSH_KEYS}_orig | sort -u > $COPYID_HOME_SSH_KEYS
            file_delete ${COPYID_HOME_SSH_KEYS}_orig
        else
            return 1
        fi
    done
}
#NAMESPACE/network/end

#NAMESPACE/shell/start
function call_command
{
    local HOST=""
    local USER="$CALL_COMMAND_DEFAULT_USER"
    local USER_SET="no"
    local TOPT="-t"
    local QUIET="no"
    local REDIRECT=""
    local PREFIX="no"
    local PIPE=""
    local LOCAL_DEBUG="no"
    local COMMAND_STRING=""
    debug check command && set_yes LOCAL_DEBUG
    debug check command && debug check right && LOCAL_DEBUG="right"
    while test $# -gt 0
    do
        test "$1" = "--host" -o "$1" = "-h" && shift && HOST="$1" && shift && continue
        test "${1%%=*}" = "--host" && HOST="${1#*=}" && shift && continue
        test "$1" = "--user" -o "$1" = "-u" && shift && USER="$1" && USER_SET="yes" && shift && continue
        test "${1%%=*}" = "--user" && USER="${1#*=}" && shift && continue

        test "$1" = "--term" -o "$1" = "-t" && TOPT="-t" && shift && continue
        test "$1" = "--noterm" -o "$1" = "-nt" && TOPT="" && shift && continue
        test "$1" = "--tterm" -o "$1" = "-tt" && TOPT="-tt" && shift && continue

        test "$1" = "--verbose" && set_no QUIET && shift && continue
        test "$1" = "--quiet" && set_yes QUIET && shift && continue
        test "$1" = "--prefix" && set_yes PREFIX && shift && continue
        test "$1" = "--debug" && set_yes LOCAL_DEBUG && shift && continue
        test "$1" = "--debug-right" && LOCAL_DEBUG="right" && shift && continue
        test "$1" = "--nodebug" && set_no LOCAL_DEBUG && shift && continue
        test "$1" = "--command-string" && shift && COMMAND_STRING="$1" && shift && continue
        break
    done

    local FILE="`file_temporary_name call_command`"
    test_no QUIET && REDIRECT="/dev/stdout" || REDIRECT="/dev/null"
    test_no PREFIX && PIPE="cat" || PIPE="pipe_echo_prefix"
    test -z "$COMMAND_STRING" && { test $# -eq 1 && COMMAND_STRING="`echo "$1"`" || COMMAND_STRING="`echo_quote "$@"`"; }
    local EXIT_CODE
    if is_localhost "$HOST"
    then
        test_yes "$LOCAL_DEBUG" && echo_debug_custom command "$COMMAND_STRING"
        test "$LOCAL_DEBUG" = "right" && echo_debug_right "$COMMAND_STRING"
        if test_no "$USER_SET" -o "`get_id`" = "$USER"
        then
            #bash -c "$@"
            eval "stdbuf -i0 -o0 -e0 $@" 2>&1 | tee "$FILE" | $PIPE > $REDIRECT
            EXIT_CODE=$?
        else
            su - "$USER" "$@" 2>&1 | tee "$FILE" | $PIPE > $REDIRECT
            EXIT_CODE=$?
        fi
    else
        USER_SSH=""
        test -n "$USER" && USER_SSH="$USER@"
        test_yes "$LOCAL_DEBUG" && echo_debug_custom command "$SSH $TOPT $USER_SSH$HOST $COMMAND_STRING"
        test "$LOCAL_DEBUG" = "right" && echo_debug_right "$SSH $TOPT $USER_SSH$HOST $COMMAND_STRING"
        $SSH $TOPT $USER_SSH$HOST "$@" 2>&1 | grep --invert-match "Connection to .* closed" | tee "$FILE" | $PIPE > $REDIRECT
        EXIT_CODE=$?
    fi

    CALL_COMMAND="`cat "$FILE"`"
    return $EXIT_CODE
}

function get_pids
# return PIDs found by command regex
{
    ps -e -o pid,ppid,cmd | $AWK --assign=p="$1" --assign=s="$$" '$1==s||$2==s||/tools_get_pids_tag/ { next; } $0~p { print $1; }';
}

function get_pids_tree_loop
# internal search function
{
    local CHECK_PID
    for CHECK_PID in $*
    do
        local CHILD_PIDS="`ps -o pid --no-headers --ppid ${CHECK_PID}`"
        test -n "$CHILD_PIDS" && get_pids_tree_loop $CHILD_PIDS && str_word add PIDS_TREE $CHILD_PIDS
        test $CHECK_PID != "$$" && str_word add PIDS_TREE $CHECK_PID
    done
}

function get_pids_tree
# return parent+child PIDs found from processes found by command regex / or by parent PIDs
# $1 regex search for parent PIDs /or/ parent PIDs
{
    local PIDS_TREE=""
    if test_integer "$1"
    then # search tree for PIDs
        get_pids_tree_loop $*
    else # search tree for PIDs from name
        local PID_LIST="`get_pids "$1"`"
        get_pids_tree_loop $PID_LIST
    fi
    echo "$PIDS_TREE"
}


function kill_tree_verbose
{
    local SPACE="$1"
    shift
    test_yes KILL_ECHO && echo_line "${SPACE}Killing tree from parent PIDs: $*"
    local CHECK_PID
    for CHECK_PID in $*
    do
        CHILD_PIDS="`ps -o pid --no-headers --ppid ${CHECK_PID}`"
        if test -n "$CHILD_PIDS"
        then
            echo_line "${SPACE}Found child PIDs from $CHECK_PID: "$CHILD_PIDS
            kill_tree_verbose "$SPACE  " $CHILD_PIDS
        else
            echo_line "${SPACE}No child PIDs from $CHECK_PID" 
        fi
        echo_line "${SPACE}Killing PID: $CHECK_PID"
        if test "$CHECK_PID" != "$$"
        then
            local PID_INFO="`ps -f --no-heading $CHECK_PID`"
            test -n "$PID_INFO" && echo_debug INFO "${SPACE}  PID $CHECK_PID killed:     <$PID_INFO>" || echo_debug INFO "  PID $CHECK_PID already killed"
            kill -9 "$CHECK_PID" 2>/dev/null
        else
            echo_line "${SPACE}  PID $CHECK_PID skipping as its me"
        fi
    done
}

function kill_tree
# $1 regexp for process name or pid
# $2 exclude PIDs
{
    local PID_LIST="`get_pids_tree "$1"`"
    test -n "$2" && PID_LIST="`command echo "$PID_LIST" | $GREP --invert-match "$2"`"
    for KILL_PID in $PID_LIST
    do
        local PID_INFO="`ps -f --no-heading $KILL_PID`"
        test -n "$PID_INFO" && echo_debug INFO "PID $KILL_PID killed:     <$PID_INFO>" || echo_debug INFO "PID $KILL_PID already killed"
        kill -9 $KILL_PID 2>/dev/null
    done
}


function fd_check
# $1 FD number to check if is opened
{
    (exec 0>&$1) 1>/dev/null 2>&1
}

function fd_find_free
{
    local FILE_FD
    for FILE_FD in 4 5 6 7 8 9 full
    do
        fd_check $FILE_FD || break
    done
    command echo $FILE_FD
}
#NAMESPACE/shell/end

#NAMESPACE/misc/start
function performance
{
    local TASK="$1"
    shift
    local VAR="${1:-default}"
    shift
    test $# -gt 0 && PERFORMANCE_MESSAGES[$VAR]="$@"
    test -n "${PERFORMANCE_MESSAGES[$VAR]}" && local MSG=" \"${PERFORMANCE_MESSAGES[$VAR]}\"" || local MSG=""
    local DATE_NOW="`date "+%s.%N" | $AWK '{ printf "%.3f", $1; }'`"
    local DATE_NOW_STR="`date +"%Y-%m-%d %H:%M:%S"`"
    case "$TASK" in
        start)
            PERFORMANCE_DATA[$VAR]="$DATE_NOW"
            test_yes PERFORMANCE_DETAILS && echo_line "Performance$MSG started on date $DATE_NOW_STR timestamp: $DATE_NOW"
            ;;
        now)
            local ELAPSED="`command echo | $AWK '{ printf "%.3f", ('$DATE_NOW' - '${PERFORMANCE_DATA[$VAR]}'); }'`"
            test_yes PERFORMANCE_DETAILS && echo_line "Performance$MSG on date $DATE_NOW_STR timestamp: $DATE_NOW elapsed: ${ELAPSED}s" || echo_line "Performance$MSG: ${ELAPSED}s"
            ;;
        end)
            local ELAPSED="`command echo | $AWK '{ printf "%.3f", ('$DATE_NOW' - '${PERFORMANCE_DATA[$VAR]}'); }'`"
            test_yes PERFORMANCE_DETAILS && echo_line "Performance$MSG ended on date $DATE_NOW_STR timestamp: $DATE_NOW elapsed: ${ELAPSED}s" || echo_line "Performance$MSG: ${ELAPSED}s"
            PERFORMANCE_DATA[$VAR]=0
            ;;
    esac
}
#NAMESPACE/misc/end

#NAMESPACE/test/start
function set_yes
# $1=yes
{
    local VAR
    for VAR in "$@"
    do
        assign "$VAR" yes
    done
}

function set_no
# $1=no
{
    local VAR
    for VAR in "$@"
    do
        assign "$VAR" no
    done
}

function test_ne0
{
    test $? -ne 0
}

function test_boolean
# $1 boolean string
{
    [[ "$1" =~ ^(y|Y|yes|Yes|YES|true|True|TRUE)$ ]]
}

function test_str_yes
# $1 test string for yes
{
    #echo "Testing string $1"
    [[ "$1" =~ ^(y|Y|yes|Yes|YES)$ ]]
}

function test_yes
# $1 yes string or variable
{
    test_str_yes "$1" && return 0
    #echo "Testing $1 - variable ${!1+exist}, $1 = ${!1}"
    test -n "${1:+exist}" && test_str_yes "${!1}" || return 1
}

function test_str_no
# $1 test string for boolean no string
{
    [[ "$1" =~ ^(n|N|no|No|NO)$ ]]
}

function test_no
# $1 no string or variable
{
    test_str_no "$1" && return 0
    test -n "${1:+exist}" && test_str_no "${!1}" || return 1
}

function test_ok
# $1 boolean ok string
{
    [[ "$1" =~ ^(ok|Ok|OK)$ ]]
}

function test_nok
# $1 boolean ok string
{
    ! test_ok "$1"
}

function test_integer
# $1 integer
{
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

function test_array
# $1 array as:
#   (item1 item2 item3)
#   [item1,item2,item3]
#   {item1:item2:item3}
{
    [[ "$1" =~ ^[[({].*[])}]$ ]]
}

function test_ip
# $1 ip
{
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

function test_str_grep
# $1 string to test
# $2 regexp
{
    local IGNORE_CASE=""
    test "$1" = "-i" -o "$1" = "--ignore-case" && IGNORE_CASE="--ignore-case" && shift
    test $# != 2 && echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT

    command echo "$1" | $GREP --quiet --extended-regexp $IGNORE_CASE "$2"
    return $?
}

function test_str
# $1 string to test
# $2 regexp
{
    local IGNORE_CASE=""
    test "$1" = "-i" -o "$1" = "--ignore-case" && IGNORE_CASE="yes" && shift
    test $# != 2 && echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT

    #test -n "$IGNORE_CASE" && local SHOPT="`shopt -p nocasematch`" && shopt -s nocasematch
    test -n "$IGNORE_CASE" && shopt -s nocasematch
    [[ "$1" =~ $2 ]]
    RETURN=$?
    #test -n "$IGNORE_CASE" && $SHOPT
    test -n "$IGNORE_CASE" && shopt -u nocasematch
    return $RETURN
}

function test_file
# $1 regexp string to test
# $2 filename
{
    test $# != 2 && echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT

    test -f "$2" || return 1

    test_str "$1" "$2"
    return $?
}

function test_cmd
# [$1] string to test
# $2 regexp
{
    local CMD="$COMMAND"

    if test $# = 2
    then
        CMD="$1"
        shift
    fi

    test_str "$CMD" "$1"
    return $?
}

function test_cmd_z
# $1 regexp
{
    test_cmd "^\$"
}

function test_opt
# $1 regexp
{
    test_str "$OPTION" "$1"
}

function test_opt2
# $1 regexp
{
    test_str "$OPTION2" "$1"
}

function test_opt_z
# $1 regexp
{
    test_str "$OPTION" "^\$"
}

function test_opt2_z
# $1 regexp
{
    test_str "$OPTION2" "^\$"
}

function test_opt_i
# $1 regexp
{
    test_integer "$OPTION"
}

function test_opt2_i
# $1 regexp
{
    test_integer "$OPTION2"
}
#NAMESPACE/test/end

function cursor_get_position
{
    if test -t 1
    then
        exec < /dev/tty
        OLD_stty=$(stty -g)
        stty raw -echo min 0
        command echo -en "\033[6n" > /dev/tty
        read -r -s -d "R" CURSOR_POSITION
        stty $OLD_stty
        CURSOR_POSITION="${CURSOR_POSITION#*[}"
    else
        CURSOR_POSITION="0;0"
    fi
    #CURSOR_POSITION="0;0"
    CURSOR_COLUMN="${CURSOR_POSITION#*;}"
    CURSOR_ROW="${CURSOR_POSITION%;*}"
}

function cursor_move_down
{
    cursor_get_position
    echo
    let CURSOR_COLUMN--
    test $CURSOR_COLUMN -gt 0 && tput cuf $CURSOR_COLUMN
}

#NAMESPACE/pipes/start
function pipe_prefix
# pipe nice output
# command | pipe_prefix
# -c <command> | --command=<command>
# -p <prefix> | --prefix=<prefix>
{
    local PREFIX="$PIPE_PREFIX"
    test -n "$SHOW_OUTPUT_PREFIX" && PREFIX="$SHOW_OUTPUT_PREFIX"

    local HIDE="$PIPE_PREFIX_HIDE"
    test -n "$SHOW_OUTPUT_HIDELINES" && HIDE="$SHOW_OUTPUT_HIDELINES"

    local COMMAND="$PIPE_PREFIX_COMMAND"
    test -n "$SHOW_OUTPUT_COMMAND" && COMMAND="$SHOW_OUTPUT_COMMAND"

    local EMPTY="$PIPE_PREFIX_EMPTY"

    local DEDUPLICATE="$PIPE_PREFIX_DEDUPLICATE"

    arguments init
    while test $# -gt 0
    do
        arguments loop
        arguments check value "p|prefix" "PREFIX" "$@"
        arguments check value "h|hide" "HIDE" "$@"
        arguments check value "c|command" "COMMAND" "$@"
        arguments check switch "l|empty" "EMPTY|yes" "$@"
        arguments check switch "|no-deduplicate" "DEDUPLICATE|no" "$@"
        arguments check switch "d|dedup" "DEDUPLICATE|yes" "$@"
        arguments check switch "|deduplicate" "DEDUPLICATE|yes" "$@"
        arguments check option "HIDE" "$@"
        arguments shift && shift $ARGUMENTS_SHIFT && continue
        echo_error_function "Unknown argument: $1" $ERROR_CODE_DEFAULT
    done
    arguments done

    #while read LINE
    #do
    #    echo "$PREFIX$LINE"
    #done

    $AWK --assign=prefix="$PREFIX" --assign=hide="$HIDE" --assign=command="$COMMAND" --assign=empty="$EMPTY" --assign=deduplicate="$DEDUPLICATE" '
        BEGIN { line=""; count=0; }
        command=="" { current=$0; }
        command!="" {
            current="";
            cmd = command " \"" $0 "\"";
            while (cmd | getline cmd_line) {
                current=current cmd_line;
            }
            close(cmd)
            #print $0 " -> " current;
        }

        empty=="no" && current=="" { next; }

        hide!="" && current~hide { next; }

        deduplicate=="yes" && current==line { count++; next; }
        deduplicate=="yes" && count==0 { line=current; count++; next; }
        deduplicate=="yes" && count==1 { print prefix line; line=current; count=1; next; }
        deduplicate=="yes" && count>1 { print prefix line " ("count"x)"; line=current; count=1; next; }
        deduplicate=="no" { print prefix current; }
        END { if (deduplicate=="yes") { if (count>1) print prefix line " ("count"x)"; else print prefix line; } }'
}

function pipe_replace
{
    if test $# -eq 2
    then
        pipe_replace_string "$1" "$2"
    elif test $# -eq 4
    then
        pipe_replace_section "$1" "$2" "$3" "$4"
    else
        echo_error_function "Wrong arguments count: $#, Arguments: `echo_quote "$@"`" $ERROR_CODE_DEFAULT
    fi
}

function pipe_replace_string
# $1 regex search
# $2 replace
{
    sed --expression="s|$1|$2|g" || echo_error_function "String `echo_quote "$1"` replace `echo_quote "$2"` error" $ERROR_CODE_DEFAULT
}

function pipe_replace_section
# $1 start replace flag
# $2 end replace flag
# $3 regex search tags: TAG1,TAG2
# $4 replace list: tag1a,tag2a;tag1b,tag2b
{
    awk \
        -v str_start="$1" \
        -v str_end="$2" \
        -v str_keywords="$3" \
        -v str_vars="$4" '
        BEGIN {
            str_keywords_count = split(str_keywords, str_keywords_array, "'"$PIPE_REPLACE_SEPARATOR_ITEM"'");
            str_vars_count = split(str_vars, str_vars_array, "'"$PIPE_REPLACE_SEPARATOR_LIST"'");
            #print "KEYWORDS(" str_keywords_count "): 1: " str_keywords_array[1] " 2: " str_keywords_array[2];
            #print "VARS(" str_vars_count ") 1: " str_vars_array[1] " 2: " str_vars_array[2];
            
            copyit=0;
        }

        $0~str_start {
            copyit = 1;
            copybuf = "";
            next;
        }
        $0~str_end {
            copyit = 0;

            for (str_vars_index=1; str_vars_index <= str_vars_count; str_vars_index++) {
                copybuf_temp = copybuf;
                str_vars1 = str_vars_array[str_vars_index];
                #print "str_vars1: " str_vars1;
                str_vars1_count = split(str_vars1, str_vars1_array, "'"$PIPE_REPLACE_SEPARATOR_ITEM"'");
                for (str_keywords_index=1; str_keywords_index <= str_keywords_count; str_keywords_index++) {
                    #print "GSUB: " str_keywords_array[str_keywords_index] " -> " str_vars1_array[str_keywords_index];
                    gsub(str_keywords_array[str_keywords_index], str_vars1_array[str_keywords_index], copybuf_temp);
                }
                print copybuf_temp;
            }

            next;
        }
        copyit == 0 {
            print $0;
            next;
        }
        copyit == 1 {
            if (copybuf == "") copybuf = $0;
            else copybuf = copybuf "\n" $0;
            next;
        }' || echo_error_function "Section `echo_quote "$1"`-`echo_quote "$2"` replace error" $ERROR_CODE_DEFAULT
}

function pipe_remove_color
# removes color control codes from pipe
{
    sed --regexp-extended \
        --expression="s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" \
        --expression="s/\\\\033\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g"
}

function pipe_join_lines
# removes new line codes from pipe
{
    if test -z "$PIPE_JOIN_LINES_CHARACTER"
    then
        $AWK '$0=="" { next; } { print; }' | tr --delete '\n' | xargs
    else
        $AWK '$0=="" { next; } { print; }' | tr '\n' "$PIPE_JOIN_LINES_CHARACTER" | xargs
    fi
}

function pipe_from
# command | pipe_from "from this line"
{
    $AWK --assign=from="$1" '
        BEGIN { show=0; }
        show==1 { print; next; }
        $0~from { show=1; print; }
    '
}

function pipe_cut
{
    local CUT_TYPE="$1"
    local -i LENGTH_MAX="$2"

    local BACKUP_IFS="$IFS"
    IFS=''
    while read LINE
    do
        #LINE="${LINE//[\t]/T}"
        local -i LENGTH_TOTAL="${#LINE}"

        test $LENGTH_TOTAL -le $LENGTH_MAX && echo "$LINE" && continue

        #echo_debug_variable LENGTH_TOTAL LENGTH_MAX LINE

        case "$CUT_TYPE" in
            center)
                local -i LENGTH_LEFT
                let LENGTH_LEFT="($LENGTH_MAX - 3) / 2"
                local -i LENGTH_RIGHT
                let LENGTH_RIGHT="$LENGTH_MAX - $LENGTH_LEFT - 3"
                local -i START_RIGHT
                let START_RIGHT="$LENGTH_TOTAL - $LENGTH_RIGHT"
                #echo_debug_variable LENGTH_LEFT START_RIGHT LENGTH_RIGHT
                echo "${LINE:0:$LENGTH_LEFT}...${LINE:$START_RIGHT}"
                ;;
            left)
                local -i LENGTH_RIGHT
                let LENGTH_RIGHT="$LENGTH_MAX - 3"
                local -i START_RIGHT
                let START_RIGHT="$LENGTH_TOTAL - $LENGTH_RIGHT"
                #echo_debug_variable START_RIGHT LENGTH_RIGHT
                echo "...${LINE:$START_RIGHT}"
                ;;
            right)
                local -i LENGTH_LEFT
                let LENGTH_LEFT="$LENGTH_MAX - 3"
                #echo_debug_variable LENGTH_LEFT
                echo "${LINE:0:$LENGTH_LEFT}..."
                ;;
        esac
    done
    IFS="$BACKUP_IFS"
}

function echo_cut
{
    local CUT_TYPE="$1"
    local -i LENGTH_MAX="$2"
    shift 2
    command echo "$@" | pipe_cut "$CUT_TYPE" "$LENGTH_MAX"
}
#NAMESPACE/pipes/end

function log
# $1 [log file pathname]
# $2 "$@"
{
    local TASK="$1"
    shift

    case "$TASK" in
        init)
            LOG_FILE="$1"
            test -z "$LOG_FILE" && LOG_FILE="${SCRIPT_FILE_NOEXT}.log"
            shift
            local LOG_TITLE_OPTIONS=""
            test -n "$1" && LOG_TITLE_OPTIONS=" `echo_quote "$@"`"

            log section
            log log "Log $TASK started on `hostname --fqdn`, command: $0$LOG_TITLE_OPTIONS" >> "$LOG_FILE"
            ;;
        done)
            test -z "$LOG_FILE" && echo_error_function "Log file is not specified"

            local LOG_DURATION
            let LOG_DURATION="`date -u +%s` - $LOG_START"

            log log "Log $TASK, script runtime $LOG_DURATION seconds" >> "$LOG_FILE"
            log section
            ;;
        section)
            test -z "$LOG_FILE" && return

            file_prepare "$LOG_FILE"
            command echo "$LOG_SECTION" >> "$LOG_FILE"
            ;;
        log)  # store pure arguments only to log file
            test -z "$LOG_FILE" && return

            file_prepare "$LOG_FILE"
            command echo "$@" >> "$LOG_FILE"
            ;;
        echo)  # echoes arguments only to log file
            test -z "$LOG_FILE" && return

            local LOG_DATE_STRING=""
            test_str "$1" "^(-d|--date)$" && LOG_DATE_STRING="`date +"$LOG_DATE"`" shift
            test_yes "$LOG_WITHDATE" && LOG_DATE_STRING="`date +"$LOG_DATE"`"

            file_prepare "$LOG_FILE"
            #echo "${LOG_SPACE}$@" | sed --expression='s/\\n/\n                    /g' --expression='s/^/                    /g' >> "$LOG_FILE"
            command echo "${LOG_SPACE}${LOG_DATE_STRING} $@" | pipe_remove_color >> "$LOG_FILE"
            #command echo "${LOG_SPACE}${LOG_DATE_STRING} $@" >> "$LOG_FILE"
            ;;
        *)
            log echo "$@"
            ;;
    esac
}

function log_output
{
    pipe_log
}

function pipe_log
# pipe with command log echo
{
    local BACKUP_IFS="$IFS"
    IFS=''
    while read LINE
    do
        log echo "$LINE"
    done
    IFS="$BACKUP_IFS"
}

function echo_output
{
    pipe_echo
}

function pipe_echo
# pipe with echo_line
{
    local BACKUP_IFS="$IFS"
    IFS=''
    while read LINE
    do
        echo_line "$LINE"
    done
    IFS="$BACKUP_IFS"
}


function show_output
{
    pipe_prefix "$@" | pipe_echo
}

function pipe_echo_prefix
# pipe with pipe_echo and nice output
{
    pipe_prefix "$@" | pipe_echo
}

function echo_quote
# usage as standard echo with quoted arguments if needed
{
    local ARG
    local SPACE=""
    local CHECK_NEEDQUOTE=".*[*;() \"'|].*"
    #local CHECK_NEEDESCAPE="\`"
    local CHECK_VARS=".*[\$].*"
    local CHECK_DOUBLE=".*[\"].*"
    local CHECK_SINGLE=".*['].*"
    ECHO_QUOTE=""
    for ARG in "$@"
    do
        #ARG="`echo "$ARG" | sed --expression='s:\([\`]\):\\1:g'`"
        if [[ $ARG =~ $CHECK_NEEDQUOTE ]]
        then
            local QUOTE="D"
            if [[ $ARG =~ $CHECK_DOUBLE ]]
            then
                if [[ $ARG =~ $CHECK_SINGLE ]]
                then # DOUBLE SINGLE
                    QUOTE="D"
                else # ONLY DOUBLE
                    if [[ $ARG =~ $CHECK_VARS ]]
                    then
                        QUOTE="S"
                    else
                        QUOTE="D"
                    fi
                fi
            else # SINGLE or NONE
                QUOTE="D"
            fi

            if test "$QUOTE" = "D"
            then
                ARG="${ARG//\\/\\\\}"
                ARG="${ARG//\"/\\\"}"
                ARG="${ARG//\$/\\\$}"
                #command echo -e "$SPACE\"$ARG\"\c"
                ECHO_QUOTE="$ECHO_QUOTE$SPACE\"$ARG\""
            else
                #command echo -e "$SPACE'$ARG'\c"
                ECHO_QUOTE="$ECHO_QUOTE$SPACE'$ARG'"
            fi
        else
            #command echo -e "$SPACE$ARG\c"
            ARG="${ARG//\$/\\\$}"
            ECHO_QUOTE="$ECHO_QUOTE$SPACE$ARG"
        fi
        SPACE=" "
    done
    #echo
    echo "$ECHO_QUOTE"
}

function echo_line
# usage as standard echo
# echoes arguments to standard output and log to the file
{
    command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$@"
    log echo "$ECHO_PREFIX$ECHO_UNAME$@"
}

function echo_title
{
    #TITLE_STYLE="01234567"
    local TITLE_MSG=" $@ "
    local TITLE_LENGTH="${#TITLE_MSG}"
    local TITLE_MSG="${TITLE_STYLE:1:1}$TITLE_MSG${TITLE_STYLE:6:1}"
    local TITLE_SEQ="`eval echo "{1..$TITLE_LENGTH}"`"
    local TITLE_HEAD="${TITLE_STYLE:0:1}`printf -- "${TITLE_STYLE:3:1}%.0s" $TITLE_SEQ`${TITLE_STYLE:5:1}"
    local TITLE_TAIL="${TITLE_STYLE:2:1}`printf -- "${TITLE_STYLE:4:1}%.0s" $TITLE_SEQ`${TITLE_STYLE:7:1}"
    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_INFO$TITLE_HEAD$COLOR_RESET"
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_INFO$TITLE_MSG$COLOR_RESET"
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_INFO$TITLE_TAIL$COLOR_RESET"
        command echo -e "$COLOR_RESET\c"
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$TITLE_HEAD"
        command echo "$ECHO_PREFIX$ECHO_UNAME$TITLE_MSG"
        command echo "$ECHO_PREFIX$ECHO_UNAME$TITLE_TAIL"
    fi

    log echo "$ECHO_PREFIX$ECHO_UNAME$TITLE_HEAD"
    log echo "$ECHO_PREFIX$ECHO_UNAME$TITLE_MSG"
    log echo "$ECHO_PREFIX$ECHO_UNAME$TITLE_TAIL"
    return 0
}

function echo_info
{
    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_INFO$@$COLOR_RESET"
        command echo -e "$COLOR_RESET\c"
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$@"
    fi

    log echo "$ECHO_PREFIX$ECHO_UNAME$@"
    return 0
}

function echo_step
{
    local STEP_NUMBER=""
    local STEP_NUMBER_STR=""
    if test $# -ge 2
    then
        STEP_VARIABLE="$1"
        STEP_NUMBER=${!STEP_VARIABLE}
        STEP_NUMBER_STR="${!STEP_VARIABLE}. "
        shift
    fi

    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_STEP$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@$COLOR_RESET"
        command echo -e "$COLOR_RESET\c"
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@"
    fi

    log echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@"

    test_integer "$STEP_NUMBER" && let STEP_NUMBER++ && assign "$STEP_VARIABLE" $STEP_NUMBER
    test_str "$STEP_NUMBER" "^[a-z]$" && assign $STEP_VARIABLE "`command echo "$STEP_NUMBER" | tr "a-z" "b-z_"`"
    test_str "$STEP_NUMBER" "^[A-Z]$" && assign $STEP_VARIABLE "`command echo "$STEP_NUMBER" | tr "A-Z" "B-Z_"`"
    return 0
}

function echo_substep
{
    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_SUBSTEP$ECHO_PREFIX_SUBSTEP$@$COLOR_RESET"
        command echo -e "$COLOR_RESET\c"
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_SUBSTEP$@"
    fi

    log echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_SUBSTEP$@"
    return 0
}

#NAMESPACE/debug/start
function debug
{
    local TASK="$1"
    shift
    case "$TASK" in
        init)
            set_no DEBUG_INIT_NAMESPACES
            # in order to speed up script start, namespaces are init in echo_error_function / echo_debug_function
            #debug init_namespaces
            ;;
        init_namespaces)
            test_yes "$DEBUG_INIT_NAMESPACES" && return 0
            set_yes DEBUG_INIT_NAMESPACES

            FUNCTION_NAMESPACES[main]="$SCRIPT_NAME"
            local SCRIPT
            for SCRIPT in "$TOOLS_FILE" "$SCRIPT_FILE" "$@"
            do
                test ! -r "$SCRIPT" && continue
                local LINE
                local INCLUDE="${SCRIPT##*/}"
                local INCLUDE="${INCLUDE%.sh}/"
                local NAMESPACE=""
                while read LINE
                do
                    [[ "$LINE" =~ ^[#]NAMESPACE/([^/]+)/start$ ]] && NAMESPACE="${BASH_REMATCH[1]}/"
                    [[ "$LINE" =~ ^[#]NAMESPACE/[^/]+/end$ ]] && NAMESPACE=""
                    if [[ "$LINE" =~ ^function[\ ] ]] || [[ "$LINE" =~ [A-Za-z0-9_]\(\)$  ]]
                    then
                        local F="$LINE"
                        str_trim F
                        F="${F#function}"
                        F="${F%{}"
                        str_trim F
                        F="${F%()}"
                        str_trim F
                        #echo FUNCTION_NAMESPACES[$F]="$INCLUDE$NAMESPACE$F"
                        FUNCTION_NAMESPACES[$F]="$INCLUDE$NAMESPACE$F"
                    fi
                done < "$SCRIPT"
            done
            return 0
            ;;
        reinit_namespaces)
            set_no DEBUG_INIT_NAMESPACES
            debug init_namespaces
            ;;
        set)
            test $# = 0 && local OPTIONS="debug" || local OPTIONS="$@"
            str_word add OPTION_DEBUG $OPTIONS
            ;;
        unset)
            test $# = 0 && local OPTIONS="debug" || local OPTIONS="$@"
            str_word delete OPTION_DEBUG $OPTIONS
            ;;
        check)
            local OPTION="${1:-debug}"
            str_word check OPTION_DEBUG $OPTION
            ;;
        parse_type)
            #DEBUG_TYPES[debug]="D"
            #DEBUG_TYPES[right]="R"
            #DEBUG_TYPES[function]="F"
            #DEBUG_TYPES[variable]="V"
            DEBUG_PARSE_TYPE="${DEBUG_TYPES[$1]}"
            test -n "$DEBUG_PARSE_TYPE" && DEBUG_PARSE_TYPE="[$DEBUG_PARSE_TYPE] "
            ;;
        set_level)
            debug parse_level "$@"
            DEBUG_LEVEL=$DEBUG_PARSE_LEVEL
            DEBUG_LEVEL_STR="$DEBUG_PARSE_LEVEL_STR"
            ;;
        set_level_default)  # default level for echo_debug without argument
            debug parse_level "$@"
            DEBUG_LEVEL_DEFAULT=DEBUG_PARSE_LEVEL
            DEBUG_LEVEL_DEFAULT_STR="$DEBUG_PARSE_LEVEL_STR"
            ;;
        check_level)
            test -z "$1" && return 1
            test_integer "$1" && return 0
            local I="${DEBUG_LEVELS[$1]}"
            test_integer "$I" && return 0 || return 1
            ;;
        parse_level)
            #DEBUG_LEVELS[ALL]=100
            #DEBUG_LEVELS[TRACE]=90
            #DEBUG_LEVELS[DEBUG]=80
            #DEBUG_LEVELS[INFO]=50
            #DEBUG_LEVELS[WARN]=30
            #DEBUG_LEVELS[ERROR]=20
            #DEBUG_LEVELS[FATAL]=10
            #DEBUG_LEVELS[FORCE]=1
            #DEBUG_LEVELS[OFF]=0
            if test $# = 1
            then
                if test -z "$1"
                then
                    DEBUG_PARSE_LEVEL=""
                    DEBUG_PARSE_LEVEL_STR=""
                elif test_integer "$1"
                then
                    local S
                    for S in ${!DEBUG_LEVELS[@]}
                    do
                        test "$1" = "${DEBUG_LEVELS[$S]}" && DEBUG_PARSE_LEVEL=$1 && DEBUG_PARSE_LEVEL_STR="$S" && return 0
                    done
                    DEBUG_PARSE_LEVEL=$1
                    DEBUG_PARSE_LEVEL_STR=""
                else
                    local I="${DEBUG_LEVELS[$1]}"
                    test_integer "$I" || echo_error_function "Unknown error level \"$1\""
                    DEBUG_PARSE_LEVEL=$I
                    DEBUG_PARSE_LEVEL_STR="$1"
                fi
                return 0
            fi
            if test $# = 2
            then
                test_integer "$1" || echo_error_function "Wrong error level \"$1\""
                DEBUG_PARSE_LEVEL=$1
                DEBUG_PARSE_LEVEL_STR="$2"
                return 0
            fi
            ;;
    esac
}
#NAMESPACE/debug/end

function echo_debug_custom
# $1 debug string to be compared to OPTION_DEBUG
{
    if debug check "$1"
    then
        local ECHO_DEBUG_TYPE
        debug parse_type "$1"
        ECHO_DEBUG_TYPE="$DEBUG_PARSE_TYPE"
        shift
        local ECHO_DEBUG_LEVEL
        if test $# -ge 2 -a "$1" != "--"
        then
            debug parse_level "$1"
            local LEVEL=$DEBUG_PARSE_LEVEL
            test -n "$DEBUG_PARSE_LEVEL_STR" && ECHO_DEBUG_LEVEL="[$DEBUG_PARSE_LEVEL_STR] "
            shift
        else
            local LEVEL=$DEBUG_LEVEL_DEFAULT
            test -n "$DEBUG_LEVEL_DEFAULT_STR" && ECHO_DEBUG_LEVEL="[$DEBUG_LEVEL_DEFAULT_STR] " || ECHO_DEBUG_LEVEL=""
        fi
        test "$1" == "--" && shift
        if test $LEVEL -le $DEBUG_LEVEL
        then
            if test_yes "$OPTION_COLOR"
            then
                command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_DEBUG$ECHO_DEBUG_TYPE$ECHO_DEBUG_LEVEL$@$COLOR_RESET" > $REDIRECT_DEBUG
            else
                command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$ECHO_DEBUG_TYPE$ECHO_DEBUG_LEVEL$@" > $REDIRECT_DEBUG
            fi

            log echo --date "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$ECHO_DEBUG_TYPE$ECHO_DEBUG_LEVEL$@"
        fi
    fi
    return 0
}

function echo_debug
{
    echo_debug_custom debug "$@"
}

function echo_debug_variable
{
    if debug check variable
    then
        local LEVEL=""
        debug check_level "$1" && LEVEL="$1" && shift

        local VAR_LIST=""
        while test $# -gt 0
        do
            local VAR_NAME="$1"
            shift
            if array_variable "$VAR_NAME"
            then
                local -A VAR_ARRAY
                array_copy "$VAR_NAME" VAR_ARRAY
                #echo VAR_ARRAY_INDEXES=$VAR_ARRAY_INDEXES
                #echo \$VAR_ARRAY_INDEXES[@]=${VAR_ARRAY_INDEXES[@]}
                for VAR_ARRAY_INDEX in "${!VAR_ARRAY[@]}"
                do
                    test -n "$VAR_LIST" && VAR_LIST="$VAR_LIST "
                    #eval "VAR_LIST=\"\${VAR_LIST}\$VAR_NAME[\$VAR_ARRAY_INDEX]=\\\"\${$VAR_NAME[$VAR_ARRAY_INDEX]}\"\\\""
                    VAR_LIST="${VAR_LIST}$VAR_NAME[$VAR_ARRAY_INDEX]=${VAR_ARRAY[$VAR_ARRAY_INDEX]}"
                done
            elif ! declare -p "$VAR_NAME" > /dev/null 2>&1
            then
                test -n "$VAR_LIST" && VAR_LIST="$VAR_LIST "
                VAR_LIST="${VAR_LIST}${VAR_NAME}=<variable not found>"
            else
                test -n "$VAR_LIST" && VAR_LIST="$VAR_LIST "
                VAR_LIST="${VAR_LIST}${VAR_NAME}=\"${!VAR_NAME}\""
            fi
        done
        echo_debug_custom variable $LEVEL "$VAR_LIST"
    fi
    return 0
}

function echo_debug_function
{
    if debug check function
    then
        local LEVEL=""
        debug check_level "$1" && LEVEL="$1" && shift

        #FUNCTION_INFO="${FUNCNAME[@]}"
        #FUNCTION_INFO="${FUNCTION_INFO/echo_debug_function /}"
        #FUNCTION_INFO="${FUNCTION_INFO// / < }"
        #test "$FUNCTION_INFO" = "main" && FUNCTION_INFO="main "
        #FUNCTION_INFO="${FUNCTION_INFO/main/$SCRIPT_NAME}"
        #echo_quote "$@" > /dev/null
        #FUNCTION_INFO="${FUNCTION_INFO/ /($ECHO_QUOTE) }"

        debug init_namespaces

        local F
        F="${FUNCNAME[1]}"
        test -n "${FUNCTION_NAMESPACES[$F]}" && F="${FUNCTION_NAMESPACES[$F]}"
        echo_quote "$@" > /dev/null
        FUNCTION_INFO="$F($ECHO_QUOTE)"
        for F in "${FUNCNAME[@]:2}"
        do
            test -n "${FUNCTION_NAMESPACES[$F]}" && F="${FUNCTION_NAMESPACES[$F]}"
            FUNCTION_INFO="$FUNCTION_INFO < $F"
        done

        echo_debug_custom function $LEVEL "$FUNCTION_INFO"
    fi
    return 0
}

function echo_debug_right
# -1 shift to previous line
# $@ message
{
    local SHIFT1="no"
    local SHIFT1_MIN_FREE="20"
    if debug check right
    then
        test "$1" = "-1" && SHIFT1="yes" && shift
        if test_yes "$OPTION_COLOR"
        then
            local DEBUG_MESSAGE="$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_DEBUG$@$COLOR_RESET"
            local DEBUG_MESSAGE_STR="$ECHO_PREFIX$ECHO_UNAME$@"
        else
            local DEBUG_MESSAGE="$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$@"
            local DEBUG_MESSAGE_STR="$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$@"
        fi
        local -i SHIFT_MESSAGE="`tput cols`"
        let SHIFT_MESSAGE="$SHIFT_MESSAGE - ${#DEBUG_MESSAGE_STR}"

##############OLD
        #cursor_get_position
#tput sc
        #/bin/echo -e "\r\c" > $REDIRECT_DEBUG
        #test $SHIFT_MESSAGE -ge 25 && tput cuu1 > $REDIRECT_DEBUG && tput cuf $SHIFT_MESSAGE > $REDIRECT_DEBUG
        #/bin/echo -e "$COLOR_DEBUG$DEBUG_MESSAGE$COLOR_RESET" > $REDIRECT_DEBUG
#tput rc
        #let CURSOR_COLUMN--
        #test $CURSOR_COLUMN -ge 1 && tput cuf $CURSOR_COLUMN > $REDIRECT_DEBUG
#test $SHIFT_MESSAGE -ge 15 || cursor_move_down
##############OLD


        if test $SHIFT_MESSAGE -gt 0
        then
            cursor_get_position
            let SHIFT_MESSAGE++
#echo -en "\\033[1A"
            test_yes "$SHIFT1" && test $SHIFT_MESSAGE -le $SHIFT1_MIN_FREE && command echo -e "\r" > $REDIRECT_DEBUG
            command echo -en "\\033[${SHIFT_MESSAGE}G" > $REDIRECT_DEBUG
            test_yes "$SHIFT1" && echo -en "\\033[1A" > $REDIRECT_DEBUG
            command echo -e "$DEBUG_MESSAGE\c" > $REDIRECT_DEBUG
            command echo -en "\\033[${CURSOR_COLUMN}G" > $REDIRECT_DEBUG
            test_yes "$SHIFT1" && echo -en "\\033[1B" > $REDIRECT_DEBUG
        else
            command echo -e "\r$DEBUG_MESSAGE" > $REDIRECT_DEBUG
        fi

        debug parse_type right
        log echo --date "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$DEBUG_PARSE_TYPE$@"
    fi
    return 0
}

function echo_error
{
    local EXIT_CODE=""
    local ECHO_ERROR="$@"
    test_integer "${@:(-1)}" && local EXIT_CODE=${@:(-1)} && ECHO_ERROR="${@:1:${#@}-1}"

    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_ERROR$ECHO_PREFIX_ERROR$ECHO_ERROR!$COLOR_RESET" >&$REDIRECT_ERROR
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_ERROR$ECHO_ERROR!" >&$REDIRECT_ERROR
    fi

    log echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_ERROR$ECHO_ERROR!"

    test -n "$EXIT_CODE" && exit $EXIT_CODE
    return 0
}

function echo_error_ne0
{
    test $? -ne 0 && echo_error "$1" "$2"
}

function echo_error_exit
{
    echo_error "$1"
    exit "$2"
}

function echo_error_function
{
    #local ECHO_FUNCTION="${FUNCNAME[@]}"
    #ECHO_FUNCTION="${ECHO_FUNCTION/echo_error_function /}"
    ##ECHO_FUNCTION="${ECHO_FUNCTION/ */}"
    #ECHO_FUNCTION="${ECHO_FUNCTION// / < }"

    debug init_namespaces

    local ECHO_FUNCTION="${FUNCNAME[1]}"
    test -n "${FUNCTION_NAMESPACES[$ECHO_FUNCTION]}" && ECHO_FUNCTION="${FUNCTION_NAMESPACES[$ECHO_FUNCTION]}"
    local ECHO_ERROR="Error in function"
    local EXIT_CODE=""
    #if test $# -eq 0
    #then
        # predefined output
    #fi
    if test $# -eq 1
    then
        ECHO_ERROR="$@"
    fi
    if test $# -eq 2 && ! test_integer "$2"
    then
        ECHO_FUNCTION="$1"
        shift
        ECHO_ERROR="$@"
    fi
    if test $# -eq 3
    then
        ECHO_FUNCTION="$1"
        shift
        ECHO_ERROR="$@"
    fi
    test_integer "${@:(-1)}" && EXIT_CODE=$2 && ECHO_ERROR="${@:1:${#@}-1}"

    echo_error "[$ECHO_FUNCTION] $ECHO_ERROR" $EXIT_CODE
}

function echo_warning
{
    local EXIT_CODE=""
    local ECHO_WARNING="$@"
    test_integer "${@:(-1)}" && local EXIT_CODE=$2 && ECHO_WARNING="${@:1:${#@}-1}"

    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_WARNING$ECHO_PREFIX_WARNING$ECHO_WARNING.$COLOR_RESET" >&$REDIRECT_WARNING
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_WARNING$ECHO_WARNING." >&$REDIRECT_WARNING
    fi

    log echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_WARNING$ECHO_WARNING."

    test -n "$EXIT_CODE" && exit $EXIT_CODE
    return 0
}

#NAMESPACE/history/start
function history
# init [history file]
# restore
# store <item> - store item into history (if is not empty and same as previous)
{
    local TASK="$1"
    shift
    case "$TASK" in
        init)
            shopt -u histappend

            HISTFILE="${SCRIPT_FILE_NOEXT}.history"
            test -n "$1" && HISTFILE="$1"
            file_prepare "$HISTFILE"

            HISTCMD=1001
            HISTCONTROL=ignoredups
            HISTSIZE=1000
            HISTFILESIZE=1000
            #set -o history

            history restore
            ;;
        restore)
            test -z "$HISTFILE" && echo_error_function "History file is not specified for restore"

            history -r

            HISTORY=()
            while read LINE
            do
                test -n "$LINE" && HISTORY+=("$LINE")
            done <<< "`tac "$HISTFILE"`"
            ;;
        store)
            test -z "$1" -o "$1" = "${HISTORY[0]}" && return 0

            HISTORY=("$1" "${HISTORY[@]}")
            command echo "$1" >> "$HISTFILE"
            history -s "$1"
            ;;
        *)
            command history "$@"
    esac
}
#NAMESPACE/history/end

function arguments_check_tools
{
    arguments check switch "|ignore-unknown" "OPTION_IGNORE_UNKNOWN|yes" "$@"
    arguments check switch "|debug" "" "$@" && debug set debug
    arguments check switch "|debug-variable" "" "$@" && debug set variable
    arguments check switch "|debug-function" "" "$@" && debug set function
    arguments check switch "|debug-command" "" "$@" && debug set command
    arguments check switch "|debug-right" "" "$@" && debug set right
    arguments check value "|debug-level" "DEBUG_LEVEL|ALL|" "$@" && debug set_level $DEBUG_LEVEL
    arguments check value "|term" "OPTION_TERM|xterm|" "$@"
    arguments check switch "|prefix" "OPTION_PREFIX|yes" "$@"
    arguments check value "|color" "OPTION_COLOR|yes|yes_no" "$@" && init_colors
    arguments check switch "|no-color" "OPTION_COLOR|no" "$@" && init_colors
    arguments check switch "|uname" "OPTION_UNAME|yes" "$@"
}

function init_debug
{
    debug init
    return 0
}

function init_colors
{
    # set colors to current terminal
    #echo "Initial color usage is set to $OPTION_COLOR and using $OPTION_COLORS colors"

# echo $TERM
# ok xterm/rxvt/konsole/linux
# no dumb/sun

    # set TERM if is not set
    test -z "$TERM" -a -n "$OPTION_TERM" && TERM="$OPTION_TERM"

    # init color numbers
    test_integer "$OPTION_COLORS" || OPTION_COLORS="256"

    # init color usage if is not set
    if ! test_yes "$OPTION_COLOR" && ! test_no "$OPTION_COLOR"
    then
        if test "${TERM:0:5}" = "xterm" -o "$TERM" = "rxvt" -o "$TERM" = "konsole" -o "$TERM" = "linux" -o "$TERM" = "putty"
        then
            OPTION_COLOR="yes"
            OPTION_COLORS="256"
            test "$TERM" = "linux" && OPTION_COLORS="8"
        else
            OPTION_COLOR="no"
            OPTION_COLORS="2"
        fi
        #echo "Color is $OPTION_COLOR"
    fi

    # init color names
    if test_yes "$OPTION_COLOR"
    then
        # color definitions
        COLOR_RESET="\033[0m"

        COLOR_BLACK="\033[30m"
        COLOR_RED="\033[31m"
        COLOR_GREEN="\033[32m"
        COLOR_YELLOW="\033[33m"
        COLOR_BLUE="\033[34m"
        COLOR_MAGENTA="\033[35m"
        COLOR_CYAN="\033[36m"
        COLOR_GRAY="\033[37m"
        COLOR_LIGHT_GRAY="\033[37m"

        if test $OPTION_COLORS -gt 8
        then
            COLOR_DARK_GRAY="\033[90m"
            COLOR_LIGHT_RED="\033[91m"
            COLOR_LIGHT_GREEN="\033[92m"
            COLOR_LIGHT_YELLOW="\033[93m"
            COLOR_LIGHT_BLUE="\033[94m"
            COLOR_LIGHT_MAGENTA="\033[95m"
            COLOR_LIGHT_CYAN="\033[96m"
            COLOR_WHITE="\033[97m"

            COLOR_ORANGE="\033[38;5;208m"
            COLOR_CHARCOAL="\033[38;5;236m"
        else
            COLOR_DARK_GRAY="$COLOR_GRAY"
            COLOR_LIGHT_RED="$COLOR_RED"
            COLOR_LIGHT_GREEN="$COLOR_GREEN"
            COLOR_LIGHT_YELLOW="$COLOR_YELLOW"
            COLOR_LIGHT_BLUE="$COLOR_BLUE"
            COLOR_LIGHT_MAGENTA="$COLOR_MAGENTA"
            COLOR_LIGHT_CYAN="$COLOR_CYAN"
            COLOR_WHITE="$COLOR_LIGHT_GRAY"

            COLOR_ORANGE="$COLOR_RED"
            COLOR_CHARCOAL="$COLOR_GRAY"
        fi

        # definitions for readline / awk / prompt
        COLOR_RESET_E="\001${COLOR_RESET}\002"

        COLOR_BLACK_E="\001${COLOR_BLACK}\002"
        COLOR_RED_E="\001${COLOR_RED}\002"
        COLOR_GREEN_E="\001${COLOR_GREEN}\002"
        COLOR_YELLOW_E="\001${COLOR_YELLOW}\002"
        COLOR_BLUE_E="\001${COLOR_BLUE}\002"
        COLOR_MAGENTA_E="\001${COLOR_MAGENTA}\002"
        COLOR_CYAN_E="\001${COLOR_CYAN}\002"
        COLOR_GRAY_E="\001${COLOR_GRAY}\002"
        COLOR_LIGHT_GRAY_E="\001${COLOR_LIGHT_GRAY}\002"

        COLOR_DARK_GRAY_E="\001${COLOR_DARK_GRAY}\002"
        COLOR_LIGHT_RED_E="\001${COLOR_LIGHT_RED}\002"
        COLOR_LIGHT_GREEN_E="\001${COLOR_LIGHT_GREEN}\002"
        COLOR_LIGHT_YELLOW_E="\001${COLOR_LIGHT_YELLOW}\002"
        COLOR_LIGHT_BLUE_E="\001${COLOR_LIGHT_BLUE}\002"
        COLOR_LIGHT_MAGENTA_E="\001${COLOR_LIGHT_MAGENTA}\002"
        COLOR_LIGHT_CYAN_E="\001${COLOR_LIGHT_CYAN}\002"
        COLOR_WHITE_E="\001${COLOR_WHITE}\002"

        COLOR_ORANGE_E="\001${COLOR_ORANGE}\002"
        COLOR_CHARCOAL_E="\001${COLOR_CHARCOAL}\002"
    else
        COLOR_RESET=""

        COLOR_BLACK=""
        COLOR_RED=""
        COLOR_GREEN=""
        COLOR_YELLOW=""
        COLOR_BLUE=""
        COLOR_MAGENTA=""
        COLOR_CYAN=""
        COLOR_GRAY=""
        COLOR_LIGHT_GRAY=""

        COLOR_DARK_GRAY=""
        COLOR_LIGHT_RED=""
        COLOR_LIGHT_GREEN=""
        COLOR_LIGHT_YELLOW=""
        COLOR_LIGHT_BLUE=""
        COLOR_LIGHT_MAGENTA=""
        COLOR_LIGHT_CYAN=""
        COLOR_WHITE=""

        COLOR_ORANGE=""
        COLOR_CHARCOAL=""

        COLOR_RESET_E=""

        COLOR_BLACK_E=""
        COLOR_RED_E=""
        COLOR_GREEN_E=""
        COLOR_YELLOW_E=""
        COLOR_BLUE_E=""
        COLOR_MAGENTA_E=""
        COLOR_CYAN_E=""
        COLOR_GRAY_E=""
        COLOR_LIGHT_GRAY_E=""

        COLOR_DARK_GRAY_E=""
        COLOR_LIGHT_RED_E=""
        COLOR_LIGHT_GREEN_E=""
        COLOR_LIGHT_YELLOW_E=""
        COLOR_LIGHT_BLUE_E=""
        COLOR_LIGHT_MAGENTA_E=""
        COLOR_LIGHT_CYAN_E=""
        COLOR_WHITE_E=""

        COLOR_ORANGE_E=""
        COLOR_CHARCOAL_E=""
    fi

    # colors for echo_*
    COLOR_TITLE="$COLOR_LIGHT_YELLOW"
    COLOR_TITLE_BORDER="$COLOR_YELLOW"
    COLOR_INFO="$COLOR_LIGHT_YELLOW"
    COLOR_STEP="$COLOR_WHITE"
    COLOR_SUBSTEP="$COLOR_LIGHT_GREY"
    test $OPTION_COLORS -gt 8 && COLOR_DEBUG="$COLOR_CHARCOAL" || COLOR_DEBUG="$COLOR_BLUE"
    COLOR_ERROR="$COLOR_LIGHT_RED"
    COLOR_WARNING="$COLOR_CYAN"
    COLOR_UNAME="$COLOR_GREEN"
    COLOR_PREFIX="$COLOR_DARK_GRAY"

    #echo "Color usage is now set to $OPTION_COLOR and using $OPTION_COLORS colors for $TERM"
}

function init_tools
{
    debug set_level ALL

    arguments init
    while test $# -gt 0
    do
        arguments loop
        arguments check tools "$@"
        arguments shift && shift $ARGUMENTS_SHIFT && continue
        if test -z "$TOOLS_FILE" -a -f "$1"
        then
            TOOLS_FILE="$1"
            shift && continue
        fi
        if test "$1" = "--"
        then
            shift
            command_options fill "$@"
            break
        fi
        test_no OPTION_IGNORE_UNKNOWN && echo_error "Unknown argument for tools: $1" 1
        shift
    done
    arguments done

    SCRIPT_FILE="`readlink --canonicalize "$0"`"
    SCRIPT_FILE_NOEXT="${SCRIPT_FILE%.sh}"
    SCRIPT_FILE_NOEXT="${SCRIPT_FILE_NOEXT%.}"
    SCRIPT_NAME="`basename "$SCRIPT_FILE"`"
    SCRIPT_NAME_NOEXT="${SCRIPT_NAME%.sh}"
    SCRIPT_NAME_NOEXT="${SCRIPT_NAME_NOEXT%.}"
    SCRIPT_DIR="`dirname "$SCRIPT_FILE"`"

    test -z "$TOOLS_FILE" -a -f "$SCRIPT_DIR/tools.sh" && TOOLS_FILE="$SCRIPT_DIR/tools.sh"
    if test -f "$TOOLS_FILE"
    then
        TOOLS_FILE="`readlink --canonicalize "$TOOLS_FILE"`"
        TOOLS_NAME="`basename "$TOOLS_FILE"`"
        TOOLS_DIR="`dirname "$TOOLS_FILE"`"
    fi
}

### tools exports
test -z "${TOOLS_FILE+exist}" && declare -x TOOLS_FILE
declare -x TOOLS_NAME=""
declare -x TOOLS_DIR=""
declare -x SCRIPT_FILE=""
declare -x SCRIPT_FILE_NOEXT=""
declare -x SCRIPT_NAME=""
declare -x SCRIPT_NAME_NOEXT=""
declare -x SCRIPT_DIR=""

declare -x REDIRECT_DEBUG=/dev/stderr
declare -x REDIRECT_ERROR=/dev/stdout
declare -x REDIRECT_WARNING=/dev/stdout

declare -x OPTION_TERM="xterm" # default value if TERM is not set
declare -x OPTION_DEBUG=""
declare -x OPTION_PREFIX="no"
declare -x OPTION_COLOR="unknown"
declare -x OPTION_COLORS=-1
declare -x OPTION_UNAME=""

declare -x ECHO_PREFIX=""
declare -x ECHO_PREFIX_STEP="  "
declare -x ECHO_PREFIX_SUBSTEP="    - "
declare -x ECHO_PREFIX_DEBUG="@@@ "
declare -x ECHO_PREFIX_ERROR="Error: "
declare -x ECHO_PREFIX_WARNING="Warning: "
declare -x ECHO_UNAME=""

declare -x COLOR_BLACK COLOR_BLACK_E
declare -x COLOR_RESET COLOR_RESET_E
declare -x COLOR_RED COLOR_RED_E
declare -x COLOR_GREEN COLOR_GREEN_E
declare -x COLOR_YELLOW COLOR_YELLOW_E
declare -x COLOR_BLUE COLOR_BLUE_E
declare -x COLOR_MAGENTA COLOR_MAGENTA_E
declare -x COLOR_CYAN COLOR_CYAN_E
declare -x COLOR_GRAY COLOR_GRAY_E
declare -x COLOR_LIGHT_GRAY COLOR_LIGHT_GRAY_E

declare -x COLOR_DARK_GRAY COLOR_DARK_GRAY_E
declare -x COLOR_LIGHT_RED COLOR_LIGHT_RED_E
declare -x COLOR_LIGHT_GREEN COLOR_LIGHT_GREEN_E
declare -x COLOR_LIGHT_YELLOW COLOR_LIGHT_YELLOW_E
declare -x COLOR_LIGHT_BLUE COLOR_LIGHT_BLUE_E
declare -x COLOR_LIGHT_MAGENTA COLOR_LIGHT_MAGENTA_E
declare -x COLOR_LIGHT_CYAN COLOR_LIGHT_CYAN_E
declare -x COLOR_WHITE COLOR_WHITE_E

declare -x COLOR_ORANGE COLOR_ORANGE_E
declare -x COLOR_CHARCOAL COLOR_CHARCOAL_E

declare -x TITLE_STYLE="+|+--+|+"
declare -x TITLE_STYLE="########"
declare -x TITLE_STYLE="[ [==] ]"
declare -x COLOR_TITLE; declare -x COLOR_TITLE_BORDER
declare -x COLOR_INFO
declare -x COLOR_STEP
declare -x COLOR_SUBSTEP
declare -x COLOR_DEBUG
declare -x COLOR_ERROR
declare -x COLOR_WARNING
declare -x COLOR_UNAME
declare -x COLOR_PREFIX

declare -x -f query
declare -x -f query_yn
declare -x -f query_ny

declare -x COMMAND
declare -x OPTIONS
declare -x OPTIONS2
declare -x OPTIONS3
declare -x OPTIONS4
declare -x OPTION
declare -x OPTION1
declare -x OPTION2
declare -x OPTION3
declare -x OPTION4
declare -x OPTION5
declare -x OPTION6
declare -x OPTION7
declare -x OPTION8
declare -x OPTION9
declare -a OPTIONS_A
declare -x -f command_options;  declare -x -f fill_command_options # = command_options fill $@
                                declare -x -f insert_cmd # = command_options insert $@

declare -x -f assign
declare -x -f function_copy
declare -x -f array_variable
declare -x -f array_assign
declare -x -f array_assign_arguments
declare -x -f array_copy

declare -x -r S_TAB="`command echo -e "\t"`"
#declare -x -r S_NEWLINE="`command echo -e "\n"`"
declare -x -r S_NEWLINE=$'\n'

declare -x -f str_trim
declare -x -f str_count_chars
declare -x -f str_word                  # add / delete / check

declare -x -a ARRAY_CONVERT=()
declare -x -f str_array_convert

declare -x PARSE_URL_PREFER_LOCAL="yes" # url without protocol like host:file and ifcfg-eth0:1 treat as local file like "/etc/sysconfig/.../ifcfg-eth0:1" or remote file: "scp file host:file"
declare -x PARSE_URL
declare -x PARSE_URL_PROTOCOL
declare -x PARSE_URL_USER_HOST
declare -x PARSE_URL_USER
declare -x PARSE_URL_PASSWORD
declare -x PARSE_URL_HOST
declare -x PARSE_URL_FILE
declare -x PARSE_URL_LOCAL
declare -x -f str_parse_url

declare -x -a PARSE_ARGS=()
declare -x -f str_parse_args
declare -x -f str_get_arg
declare -x -f str_get_arg_from

declare -x -a ARGUMENTS_STORE=()        # only internal use = "$ARGUMENTS_SHIFT|$ARGUMENTS_OPTION_FOUND|$ARGUMENTS_SWITCHES_FOUND"
declare -x -a ARGUMENTS_STORE_CHECK_ALL=() # only internal use
declare -x -i ARGUMENTS_STORE_I=0       # only internal use
declare -x -i ARGUMENTS_SHIFT=0
declare -x    ARGUMENTS_OPTION_FOUND    # only internal use
declare -x    ARGUMENTS_SWITCHES_FOUND  # only internal use
declare -x -a ARGUMENTS_CHECK_ADD       # cache for check/add
declare -x -a ARGUMENTS_CHECK_ALL       # cache for check/all, lasting values are unknown arguments
declare -x -f arguments                 # init / done / loop / shift / check
#declare -x -f arguments_check_${type}
declare -x -f arguments_check           # switch / value / option / tools
declare -x -f arguments_check_info
declare -x -f arguments_check_tools     # checks for standard tools.sh arguments
#declare -x -f arguments_tester_${check}
declare -x    ARGUMENTS_NAME            # current specified switch
declare -x    ARGUMENTS_VALUE_ORIGINAL  # tester can obtain original value set in variable before
declare -x    ARGUMENTS_VALUE           # current proposed value from switch / value / option, can be changed
declare -x    ARGUMENTS_VALUE_DELIMITER=" " # delimiter to use for /append variable
declare -x -f arguments_tester_info
declare -x -f arguments_tester_file_exist
declare -x -f arguments_tester_file_read
declare -x -f arguments_tester_file_write
declare -x -f arguments_tester_file_canonicalize
declare -x -f arguments_tester_ping
declare -x -f arguments_tester_increase

declare -x -a FILE_FIND
declare -x -f file_find
declare -x -f file_loop

declare -x -f file_temporary_name
declare -x -f file_delete
declare -x -f file_prepare

declare -x    FILE_REMOTE
declare -x -f file_remote               # get / put

declare -x -f file_line_delete_local
declare -x -f file_line_add_local
declare -x -f file_line_set_local
declare -x -f file_line                 # add / delete / set
declare -x -f file_replace
declare -x    FILE_CONFIG_PREFIX="CONFIG_"  # prefix before variables name for read function
declare -x -A CONFIG=()                 # default array name to store values
declare -x -f file_config               # format / get / read / set

declare -x -f check_ssh
declare -x -f check_internet

declare -x -f check_ping
declare -x -f get_ip_arp
declare -x -f get_ip_ping
declare -x -f get_ip
declare -x -f is_localhost
declare -x -f get_id

declare -x -f ssh_scanid
declare -x -f ssh_scanremoteid
declare -x -f ssh_exportid
declare -x -f ssh_importid

declare -x    CALL_COMMAND_DEFAULT_USER=""
declare -x    CALL_COMMAND_OUTPUT=""
declare -x -f call_command

declare -x -f get_pids
declare -x -f get_pids_tree_loop
declare -x -f get_pids_tree
#declare -x -f kill_tree_verbose
declare -x -f kill_tree

declare -x -f fd_check
declare -x -f fd_find_free

declare -x    PERFORMANCE_DETAILS="yes" # show detailed output / show only elapsed time
declare -x -A PERFORMANCE_DATA          # only internal use
declare -x -A PERFORMANCE_MESSAGES      # only internal use
#PERF_DATA["default"]=0
declare -x -f performance               # start / now /end

declare -x -f set_yes
declare -x -f test_ne0
declare -x -f test_boolean
declare -x -f test_str_yes
declare -x -f test_yes
declare -x -f test_str_no
declare -x -f test_no
declare -x -f test_ok
declare -x -f test_nok
declare -x -f test_integer
declare -x -f test_str;         declare -x -f test_str_grep
declare -x -f test_file
declare -x -f test_cmd
declare -x -f test_cmd_z
declare -x -f test_opt
declare -x -f test_opt2
declare -x -f test_opt_z
declare -x -f test_opt2_z
declare -x -f test_opt_i
declare -x -f test_opt2_i

declare -x    CURSOR_POSITION="0;0"
declare -x -i CURSOR_COLUMN=0
declare -x -i CURSOR_ROW=0
declare -x -f cursor_get_position
declare -x -f cursor_move_down

declare -x PIPE_PREFIX="  >  "
declare -x PIPE_PREFIX_HIDE=""     # regexp to hide lines
declare -x PIPE_PREFIX_COMMAND=""
declare -x PIPE_PREFIX_EMPTY="no"
declare -x PIPE_PREFIX_DEDUPLICATE="yes"
declare -x -f pipe_prefix
declare -x PIPE_REPLACE_SEPARATOR_ITEM=","
declare -x PIPE_REPLACE_SEPARATOR_LIST=";"
declare -x -f pipe_replace
declare -x -f pipe_replace_string
declare -x -f pipe_replace_section
declare -x -f pipe_remove_color
PIPE_JOIN_LINES_CHARACTER=" "
declare -x -f pipe_join_lines
declare -x -f pipe_from
declare -x -f pipe_cut
declare -x -f echo_cut

declare -x LOG_FILE=""
declare -x LOG_WITHDATE="yes"
declare -x LOG_DATE="%Y-%m-%d %H:%M:%S"
declare -x LOG_SECTION="=============================================================================="
declare -x LOG_SPACE=""
declare -x LOG_START="`date -u +%s`"
declare -x -f log                       # init / done / section / log | echo

declare -x -f pipe_log;         declare -x -f log_output
declare -x -f pipe_echo;        declare -x -f echo_output
declare -x -f pipe_echo_prefix; declare -x -f show_output

declare -x ECHO_QUOTE
declare -x -f echo_quote
declare -x -f echo_line
declare -x -f echo_title
declare -x -f echo_info
declare -x -f echo_step
declare -x -f echo_substep

declare -x    DEBUG_INIT_NAMESPACES="no"
declare -x -A DEBUG_TYPES
DEBUG_TYPES[debug]="D"
DEBUG_TYPES[right]="R"
DEBUG_TYPES[function]="F"
DEBUG_TYPES[variable]="V"
DEBUG_TYPES[command]="C"
declare -x -i DEBUG_LEVEL
declare -x    DEBUG_LEVEL_STR
declare -x -i DEBUG_LEVEL_DEFAULT=80
declare -x    DEBUG_LEVEL_DEFAULT_STR=""
declare -x -A DEBUG_LEVELS
DEBUG_LEVELS[ALL]=100
DEBUG_LEVELS[TRACE]=90
DEBUG_LEVELS[DEBUG]=80
DEBUG_LEVELS[INFO]=50
DEBUG_LEVELS[WARN]=30
DEBUG_LEVELS[ERROR]=20
DEBUG_LEVELS[FATAL]=10
DEBUG_LEVELS[FORCE]=1
DEBUG_LEVELS[OFF]=0
declare -x -f debug                     # init / init_namespaces / reinit_namespaces
                                        # set / unset / check / set_level / set_level_default / check_level / parse_level
declare -x    DEBUG_PARSE_LEVEL
declare -x    DEBUG_PARSE_LEVEL_STR

declare -x -f echo_debug_custom
declare -x -f echo_debug
declare -x -f echo_debug_variable
declare -x -f echo_debug_function
declare -x -f echo_debug_right
declare -x -i ERROR_CODE_DEFAULT=99
declare -x -f echo_error
declare -x -f echo_error_ne0
declare -x -A FUNCTION_NAMESPACES=()
declare -x -f echo_error_function
declare -x -f echo_error_exit
declare -x -f echo_warning

declare -x -f history                   # init / restore / store

declare -x OPTION_IGNORE_UNKNOWN="yes"
declare -x -f arguments_check_tools
declare -x -f init_debug
declare -x -f init_colors
declare -x -f init_tools

### tools init
init_debug
init_colors
init_tools "$@"

# set echo prefix or uname prefix
test_yes OPTION_PREFIX && ECHO_PREFIX="### " || ECHO_PREFIX=""
test -n "$ECHO_PREFIX" && ECHO_PREFIX_C="$COLOR_PREFIX$ECHO_PREFIX$COLOR_RESET"
test_yes OPTION_UNAME && ECHO_UNAME="`uname -n`: " || ECHO_UNAME=""
test -n "$ECHO_UNAME" && ECHO_UNAME_C="$COLOR_UNAME$ECHO_UNAME$COLOR_RESET"

return 0
