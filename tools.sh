#!/bin/bash

# execute as: ". <thisname> <thisname> [options]"
# example:
#       export TOOLS_FILE="`dirname $0`/tools.sh"
#       . "$TOOLS_FILE" --debug-right

# options:
# --prefix
# --color=yes|no
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
    declare -x REPLY=""
    declare -x QUERY_REPLY=""

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

    declare -x REPLY
    declare -x QUERY_REPLY="$REPLY"
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
        declare -x COMMAND="$1"
        declare -x OPTIONS="$2 $3 $4 $5 $6 $7 $8 $9"
        declare -x OPTIONS2="$3 $4 $5 $6 $7 $8 $9 ${10}"
        declare -x OPTIONS3="$4 $5 $6 $7 $8 $9 $10 ${11}"
        declare -x OPTIONS4="$5 $6 $7 $8 $9 $10 $11 ${12}"
        declare -x OPTION="$2"
        declare -x OPTION1="$2"
        declare -x OPTION2="$3"
        declare -x OPTION3="$4"
        declare -x OPTION4="$5"
        declare -x OPTION5="$6"
        declare -x OPTION6="$7"
        declare -x OPTION7="$8"
        declare -x OPTION8="$9"
        declare -x OPTION9="${10}"
        unset OPTIONS_A
        declare -a OPTIONS_A=("$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}")
    fi
    if test "$TASK" = "parse"
    then
        declare -x COMMAND="`str_get_arg "$INPUT" 1`"
        declare -x OPTIONS="`str_get_arg_from "$INPUT" 2`"
        declare -x OPTIONS2="`str_get_arg_from "$INPUT" 3`"
        declare -x OPTIONS3="`str_get_arg_from "$INPUT" 4`"
        declare -x OPTIONS4="`str_get_arg_from "$INPUT" 5`"
        declare -x OPTION="`str_get_arg "$INPUT" 2`"
        declare -x OPTION1="`str_get_arg "$INPUT" 2`"
        declare -x OPTION2="`str_get_arg "$INPUT" 3`"
        declare -x OPTION3="`str_get_arg "$INPUT" 4`"
        declare -x OPTION4="`str_get_arg "$INPUT" 5`"
        declare -x OPTION5="`str_get_arg "$INPUT" 6`"
        declare -x OPTION6="`str_get_arg "$INPUT" 7`"
        declare -x OPTION7="`str_get_arg "$INPUT" 8`"
        declare -x OPTION8="`str_get_arg "$INPUT" 9`"
        declare -x OPTION9="`str_get_arg "$INPUT" 10`"
        unset OPTIONS_A
        declare -a OPTIONS_A=("$OPTION" "$OPTION2" "$OPTION3" "$OPTION4" "$OPTION5" "$OPTION6" "$OPTION7" "$OPTION8" "$OPTION9")
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
    #export -n "$1"+="$2" !!!WHY?!!!
    #echo printf -v "$1" '%s' "$2"
    printf -v "$1" '%s' "$2"
}

#NAMESPACE/string/start
function str_trim
{
    local STR="$@"
    test -n "${!@+exist}" && STR="${!@}"
    #echo "STR=$STR"
    STR="${STR#"${STR%%[![:space:]]*}"}"   # remove leading whitespace characters
    STR="${STR%"${STR##*[![:space:]]}"}"   # remove trailing whitespace characters
    test -n "${!@+exist}" && assign "${!@}" "$STR" || echo -n "$STR"
}

function str_add_word
# add word if not present delimited by space to string or variable
# $1 variable or string
# $2 word
{
    local STR="$1"
    test -n "${!1+exist}" && STR="${!1}"
    test_str "$STR" "\b$2\b" && return 0
    test -n "$STR" && STR="$STR "
    STR="$STR$2"
    test -n "${!1+exist}" && assign "$1" "$STR" || echo -n "out=$STR"
}

function str_delete_word
# delete word delimited by start/spaces/end from string or variable
# $1 variable or string
# $2 word
{
    local STR="$1"
    test -n "${!1+exist}" && STR="${!1}"
    STR="${STR% $2}"
    STR="${STR#$2 }"
    STR="${STR/ $2 / }"
    test -n "${!1+exist}" && assign "$1" "$STR" || echo -n "out=$STR"
    test -n "${!1+exist}" && echo a || echo b
}

function str_parse_url
# $1 URL
#   [path/]filename
#   host:[path/]filename
#   user@host:[path/]filename
#   protocol://user@host:[path/]filename
# $2 AVAR       - associative array variable name to store values in
#   ${2[PROTOCOL]}
#   ${2[USER_HOST]}
#   ${2[HOST]}
#   ${2[USER]}
#   ${2[FILE]}
{
    PARSE_URL="$1"
    if test_str "$PARSE_URL" "^([^:/]+):(.*)$"
    then
        PARSE_URL_PROTOCOL="ssh"
        PARSE_URL_USER_HOST="${BASH_REMATCH[1]}"
        PARSE_URL_FILE="${BASH_REMATCH[2]}"
        test_str "$PARSE_URL_USER_HOST" "((.*)@)?(.*)$"
        PARSE_URL_USER="${BASH_REMATCH[2]}"
        PARSE_URL_HOST="${BASH_REMATCH[3]}"
    else
        PARSE_URL_PROTOCOL="file"
        PARSE_URL_USER_HOST=""
        PARSE_URL_USER=""
        PARSE_URL_HOST=""
        PARSE_URL_FILE="$PARSE_URL"
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
        assign "$2[HOST]" "$PARSE_URL_HOST"
        assign "$2[FILE]" "$PARSE_URL_FILE"
    fi
}

function str_parse_args
# $1 string with arguments and options in ""
# !!! $2 destination array variable
{
    unset PARSE_ARGS
    declare -a PARSE_ARGS=()

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
        declare -x PARSE_ARGS_$C="$V"
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

function check_arg_init
{
    CHECK_ARG_SHIFTS[$CHECK_ARG_SHIFTS_I]=$CHECK_ARG_SHIFT
    let CHECK_ARG_SHIFTS_I++
}

function check_arg_done
{
    let CHECK_ARG_SHIFTS_I--
    CHECK_ARG_SHIFT=${CHECK_ARG_SHIFTS[$CHECK_ARG_SHIFTS_I]}
    unset CHECK_ARG_SHIFTS[$CHECK_ARG_SHIFTS_I]
}

function check_arg_loop
{
    CHECK_ARG_SHIFT=0
}

function check_arg_shift
{
    test $CHECK_ARG_SHIFT -ne 0
}

function check_arg_switch
# $1 short|long
# $2 variable|default
# $3 arguments
# usage: check_arg_switch "d|debug" "OPTION_DEBUG|default" "$@"
# example:
# check_arg_init
# while test $# -gt 0
# do
#     check_arg_loop
#     check_arg_switch "d|debug" "OPTION_DEBUG|yes" "$@"
#     check_arg_value "h|host" "OPTION_HOST|localhost" "$@"
#     check_arg_shift && shift $CHECK_ARG_SHIFT && continue
#     echo_error "Unknown argument: $1" 1
# done
# check_arg_done
{
    ARG_NAME_SHORT="${1%|*}"
    ARG_NAME_LONG="${1#*|}"
    #ARG_NAME_VAR="${2%|*}"
    #ARG_NAME_VALUE="${2#*|}"
    #shift 2
    #echo_debug_variable ARG_NAME_SHORT ARG_NAME_LONG ARG_NAME_VAR ARG_NAME_VALUE

    if test "$3" = "--$ARG_NAME_LONG" -o "$3" = "-$ARG_NAME_SHORT"
    then
        ARG_NAME_VAR="${2%|*}"
        ARG_NAME_VALUE="${2#*|}"
        test -n "$ARG_NAME_VAR" && declare -x ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    return 1
}

function check_arg_value
# $1 short|long
# $2 variable|default
# $3 arguments
# usage: check_arg_value "h|host" "OPTION_HOST" "$@"
# example:
# check_arg_init
# while test $# -gt 0
# do
#     check_arg_loop
#     check_arg_switch "d|debug" "OPTION_DEBUG|yes" "$@"
#     check_arg_value "h|host" "OPTION_HOST|localhost" "$@"
#     check_arg_shift && shift $CHECK_ARG_SHIFT && continue
#     echo_error "Unknown argument: $1" 1
# done
# check_arg_done
{
    ARG_NAME_SHORT="${1%|*}"
    ARG_NAME_LONG="${1#*|}"
    ARG_NAME_VAR="${2%|*}"
    ARG_NAME_VALUE="${2#*|}"
    shift 2
    #echo_debug_variable ARG_NAME_SHORT ARG_NAME_LONG ARG_NAME_VAR ARG_NAME_VALUE

    if test "$1" = "--$ARG_NAME_LONG" -o "$1" = "-$ARG_NAME_SHORT"
    then
        if test $# -eq 1
        then
            test -n "${ARG_NAME_VAR}" && declare -x ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
            CHECK_ARG_SHIFT+=1 && return 0 #echo_error "Missing value for argument \"$1\"" $ERROR_CODE_DEFAULT
        elif test "${2:0:1}" != "-"
        then
            test -n "${ARG_NAME_VAR}" && declare -x ${ARG_NAME_VAR}="$2"
            CHECK_ARG_SHIFT+=1
        else
            declare -x ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
        fi
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    if test "${1%%=*}" = "--$ARG_NAME_LONG"
    then
        declare -x ${ARG_NAME_VAR}="${1#*=}"
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    return 1
}
#NAMESPACE/string/end

#NAMESPACE/file/start
function file_temporary_name
# $1 temporary file prefix
# $2 source filename to be use as part of temporary filename
{
    echo "/tmp/`basename "$2"`.$1.$$.tmp"
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
    check_arg_init
    while test $# -gt 0
    do
        check_arg_loop
        check_arg_switch "e|empty" "EMPTY|yes" "$@"
        check_arg_switch "r|roll" "ROLL|yes" "$@"
        check_arg_switch "u|user" "USER|" "$@"
        check_arg_switch "g|group" "GROUP|" "$@"
        check_arg_shift && shift $CHECK_ARG_SHIFT && continue
        test -z "$FILE" && FILE="$1" && shift && continue
        echo_error_function "Unknown argument: $1" $ERROR_CODE_DEFAULT
    done
    check_arg_done
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
    test -w "$FILE" || echo_error_function "Can't create and prepare file for writting: `echo_quote $FILE`" $ERROR_CODE_DEFAULT

    test_yes "$EMPTY" && cat /dev/null > "$FILE"

    test -n "$USER" && chgrp "$USER" "$FILE" 2> /dev/null
    test -n "$GROUP" && chown "$GROUP" "$FILE" 2> /dev/null

    return 0
}

function prepare_file
{
    file_prepare "$@"
}

function file_remote_get
# $1 user@host:remote_file
# $2 local file
{
    local SSH="${1%%:*}"
    local FILE="${1#*:}"
    declare -x FILE_REMOTE="`file_temporary_name file_remote "$FILE"`"
    test -n "$2" && FILE_REMOTE="$2"
    file_delete "$FILE_REMOTE"
    $SCPq "$SSH":"$FILE" "$FILE_REMOTE" || return 1
}

function file_remote_put
# $1 user@host:remote_file
# $2 local file
{
    local SSH="${1%%:*}"
    local FILE="${1#*:}"
    declare -x FILE_REMOTE="`file_temporary_name file_remote "$FILE"`"
    test -n "$2" && FILE_REMOTE="$2"
    $SCPq "$FILE_REMOTE" "$SSH":"$FILE" || return 1
    file_delete "$FILE_REMOTE"
}

function file_line_remove_local
# $1 filename
# $2 remove regexp
{
    local FILE="$1"
    local TEMP_FILE="`file_temporary_name file_line_remove_local "$FILE"`"
    local REGEXP="$2"
    local ERROR_MSG="Remove line \"$REGEXP\" from file `echo_quote "$FILE"` fail"
    if test -r "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        if diff "$FILE" "$TEMP_FILE" > /dev/null 2> /dev/null
        then
            cat "$TEMP_FILE" 2> /dev/null | $GREP --invert-match "$REGEXP" > "$FILE" 2> /dev/null
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
            cat "$TEMP_FILE" | $AWK --assign=line="$LINE" 'BEGIN { p=0; gsub(/\n/, "\\n", line); } p==0&&/'"$REGEXP_REPLACE"'/ { p=1; print line; next } { print; } END { if (p==0) print line; }' > "$FILE"
        elif test -n "$REGEXP_AFTER" && `cat "$TEMP_FILE" | $AWK 'BEGIN { f=1; } /'"$REGEXP_AFTER"'/ { f=0; } END { exit f; }'`
        then
            cat "$TEMP_FILE" | $AWK --assign=line="$LINE" 'BEGIN { p=0; gsub(/\n/, "\\n", line); } p==0&&/'"$REGEXP_AFTER"'/ { print $0; p=1; print line; next } { print; } END { if (p==0) print line; }' > "$FILE"
        else
            cat "$TEMP_FILE" | $AWK --assign=line="$LINE" 'BEGIN { gsub(/\n/, "\\n", line); } { print; } END { print line; }' > "$FILE"
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

function file_line_add1
{
    file_line_set "$@"
}

function file_line
# $1 can be [[user@]host:][path/]filename
# $* as for file_line_add_local function
{
    local LINE="$1"
    test_str "$LINE" "(remove|add|set)" || echo_error_function "Unsupported function: $LINE. Supported: remove add set" $ERROR_CODE_DEFAULT
    local -A URL
    str_parse_url "$2" URL
    shift 2
    if test "${URL[PROTOCOL]}" = "file" || is_localhost "${URL[HOST]}"
    then
        file_line_${LINE}_local "${URL[FILE]}" "$@"
    else
        file_remote_get "${URL[URL]}" || echo_error_function "Can't retrieve `echo_quote "${URL[FILE]}"` file from ${URL[USER_HOST]}" $ERROR_CODE_DEFAULT
        #ls -la "$FILE_REMOTE"
        file_line_${LINE}_local "$FILE_REMOTE" "$@"
        #ls -la "$FILE_REMOTE"
        file_remote_put "${URL[URL]}" || echo_error_function "Can't upload `echo_quote "$FILE_REMOTE"` file to ${URL[USER_HOST]}" $ERROR_CODE_DEFAULT
    fi
}

function file_config_format
# $1 filename
{
    local CONFIG_FILE="$1"
    local FORMAT="standard"
    test -e "$CONFIG_FILE" && $GREP "^[\t ]\[" "$CONFIG_FILE" && FORMAT="extended"
    echo "$FORMAT"
}

function file_config_set
# $1 filename
# $2 option
# $3 new value
{
    local CONFIG_FILE="$1"
    local CONFIG_TEMP_FILE="`file_temporary_name file_config_set "$CONFIG_FILE"`"
    local OPTION_SECTION="`dirname "$2"`"
    local OPTION_NAME="`basename "$2"`"
    local VALUE="$3"
    local ERROR_MSG="Configuration \"$OPTION_NAME=\"$VALUE\"\" change to file `echo_quote "$CONFIG_FILE"` fail"
    if test -e "$CONFIG_FILE"
    then
        cat "$CONFIG_FILE" > "$CONFIG_TEMP_FILE" || echo_error_function "$ERROR_MSG, temporary file create `echo_quote "$CONFIG_TEMP_FILE"` problem" $ERROR_CODE_DEFAULT
        test -w "$CONFIG_FILE" || echo_error_function "$ERROR_MSG, file not writable" $ERROR_CODE_DEFAULT
        $AWK 'BEGIN { opt_val="'"$OPTION_NAME"'=\"'"$VALUE"'\""; found=0; s=0; }
            "'"$OPTION_SECTION"'" != "." && /^[\t ]*\[.*\][\t ]*$/ {
                s=0; }
            "'"$OPTION_SECTION"'" != "." && /^[\t ]*\['"$OPTION_SECTION"'\][\t ]*$/ {
                s=1; }
            s==1 && /^[\t ]*'$OPTION_NAME'[\t ]*=[\t ]*/ {
                print opt_val; found=1; next; }
            { print; }
            END { if (found == 0) { if ("'"$OPTION_SECTION"'" != "." ) print "['"$OPTION_SECTION"']"; print opt_val; } }' "$CONFIG_TEMP_FILE" > "$CONFIG_FILE"
        if test -s "$CONFIG_FILE"
        then
            file_delete "$CONFIG_TEMP_FILE"
        else
            cat "$CONFIG_TEMP_FILE" > "$CONFIG_FILE"
            file_delete "$CONFIG_TEMP_FILE"
            echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        fi
    else
        if test "$OPTION_SECTION" = "."
        then
            echo "$OPTION_NAME=\"$VALUE\"" > "$CONFIG_FILE" || echo_error_function "$ERROR_MSG, file create problem" $ERROR_CODE_DEFAULT
        else
            echo "[$OPTION_SECTION]" > "$CONFIG_FILE" || echo_error_function "$ERROR_MSG, file create problem" $ERROR_CODE_DEFAULT
            echo "$OPTION_NAME=\"$VALUE\"" >> "$CONFIG_FILE"
        fi
    fi
}

function file_config_get
# Read and output value from option
# -n|--noeval - do not evaluate readed value
# $1 filename
# $2 option
# $3 default value
{
    local DO_EVAL="yes"
    test_str "$1" "(-e|--eval)" && set_yes DO_EVAL && shift
    test_str "$1" "(-n|--noeval)" && set_no DO_EVAL && shift

    local CONFIG_FILE="$1"
    local OPTION_SECTION="`dirname "$2"`"
    local OPTION_NAME="`basename "$2"`"
    local VALUE="$3"
    if test -r "$CONFIG_FILE"
    then
#A="  A = \"\$USER \" "; echo "-$A-"; B="`echo "$A" | awk '/^[\t ]*A[\t ]*=[\t ]*/ { sub(/^[\t ]*A[\t ]*=[\t ]*/, ""); sub(/^["]/, ""); sub(/["]*[\t ]*$/, ""); print; }'`"; eval "set O=\"$B\""; echo "-$B-$O-"
        VALUE="`$AWK 'BEGIN { if ("'"$OPTION_SECTION"'" == ".") s=1; else s=0; }
            /* { print "LINE=" $0; } */
            "'"$OPTION_SECTION"'" != "." && /^[\t ]*\[.*\][\t ]*$/ {
                s=0; }
            "'"$OPTION_SECTION"'" != "." && /^[\t ]*\['"$OPTION_SECTION"'\][\t ]*$/ {
                s=1; next; }
            s==1 && /^[\t ]*'"$OPTION_NAME"'[\t ]*=[\t ]*/ {
                sub(/^[\t ]*'"$OPTION_NAME"'[\t ]*=[\t ]*/, ""); sub(/^["]/, ""); sub(/["][\t ]*$/, ""); print; }' "$CONFIG_FILE"`"
    fi
    test_yes DO_EVAL && eval "command echo \"$VALUE\"" || command echo "$VALUE"
}

function file_config_read
# Read and store value into option variable
# -n|--noeval - do not evaluate readed value
# $1 filename
# $2 option
# $3 default value
{
    local VALUE="`file_config_get "$@"`"
    test_str "$1" "(-e|--eval|-n|--noeval)" && shift
    local OPTION_SECTION="`dirname "$2"`"
    local OPTION_NAME="`basename "$2"`"

    test "$OPTION_SECTION" != "." && declare -x ${OPTION_SECTION}_${OPTION_NAME}="$VALUE"
    declare -x $OPTION_NAME="$VALUE"
}

function file_replace
# $1 filename
# $2 search
# $3 replace
{
    local FILE="$1"
    local TEMP_FILE="`file_temporary_name file_replace "$FILE"`"
    local SEARCH="$2"
    local REPLACE="$3"
    local ERROR_MSG="File `echo_quote "$FILE"` string \"$SEARCH\" replace fail"
    if test -e "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG, temporary file create `echo_quote "$TEMP_FILE"` problem" $ERROR_CODE_DEFAULT
        cat "$TEMP_FILE" | sed --expression="s|$SEARCH|$REPLACE|g" > "$FILE" || echo_error_function "$ERROR_MSG" $ERROR_CODE_DEFAULT
        file_delete "$TEMP_FILE"
    fi
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
    UNAME_N="`uname -n`"
    #echo_debug_variable UNAME_N
    test "$1" = "$UNAME_N" && return 0

    # IP test
    UNAME_IP="`get_ip "$UNAME_N"`"
    REMOTE_IP="`get_ip "$1"`"
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
    local TOPT="-t"
    local USER="$CALL_COMMAND_DEFAULT_USER"
    local USER_SET="no"
    local LOCAL_DEBUG="no"
    debug_check command && set_yes LOCAL_DEBUG
    debug_check command && debug_check right && LOCAL_DEBUG="right"
    while test $# -gt 0
    do
        test "$1" = "--debug" && set_yes LOCAL_DEBUG && shift && continue
        test "$1" = "--debug-right" && LOCAL_DEBUG="right" && shift && continue
        test "$1" = "--nodebug" && set_no LOCAL_DEBUG && shift && continue
        test "$1" = "--term" -o "$1" = "-t" && TOPT="-t" && shift && continue
        test "$1" = "--noterm" -o "$1" = "-nt" && TOPT="" && shift && continue
        test "$1" = "--tterm" -o "$1" = "-tt" && TOPT="-tt" && shift && continue
        test "$1" = "--host" -o "$1" = "-h" && shift && HOST="$1" && shift && continue
        test "${1%%=*}" = "--host" && HOST="${1#*=}" && shift && continue
        test "$1" = "--user" -o "$1" = "-u" && shift && USER="$1" && USER_SET="yes" && shift && continue
        test "${1%%=*}" = "--user" && USER="${1#*=}" && shift && continue
        break
    done

    local COMMAND_STRING="`echo_quote "$@"`"
    test $# = 1 && COMMAND_STRING="$@"
    local EXIT_CODE
    if is_localhost "$HOST"
    then
        test_yes "$LOCAL_DEBUG" && echo_debug_custom command "$COMMAND_STRING"
        test "$LOCAL_DEBUG" = "right" && echo_debug_right "$COMMAND_STRING"
        if test_no "$USER_SET" -o "`get_id`" = "$USER"
        then
            #bash -c "$@"
            eval "stdbuf -i0 -o0 -e0 $@"
            EXIT_CODE=$?
        else
            su - "$USER" "$@"
            EXIT_CODE=$?
        fi
    else
        USER_SSH=""
        test -n "$USER" && USER_SSH="$USER@"
        test_yes "$LOCAL_DEBUG" && echo_debug_custom command "$SSH $TOPT $USER_SSH$HOST $COMMAND_STRING"
        test "$LOCAL_DEBUG" = "right" && echo_debug_right "$SSH $TOPT $USER_SSH$HOST $COMMAND_STRING"
        $SSH $TOPT $USER_SSH$HOST "$@" 2>&1 | grep --invert-match "Connection to .* closed"
        EXIT_CODE=$?
    fi

    return $EXIT_CODE
}

function get_pids
{
    ps -e -o pid,ppid,cmd | $AWK --assign=p="$1" --assign=s="$$" '$1==s||$2==s||/tools_get_pids_tag/ { next; } $0~p { print $1; }';
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
            if test_yes KILL_ECHO
            then
                local PID_INFO="`ps -f --no-heading $CHECK_PID`"
                test -n "$PID_INFO" && echo_line "${SPACE}  PID $CHECK_PID killed:     <$PID_INFO>" || echo_line "  PID $CHECK_PID already killed"
            fi
            kill -9 "$CHECK_PID" 2>/dev/null
        else
            echo_line "${SPACE}  PID $CHECK_PID skipping as its me"
        fi
    done
}

function kill_tree
{
    #echo_line "Kill tree: $*"
    local CHECK_PID
    for CHECK_PID in $*
    do
        CHILD_PIDS="`ps -o pid --no-headers --ppid ${CHECK_PID}`"
        test -n "$CHILD_PIDS" && kill_tree $CHILD_PIDS
        if test "$CHECK_PID" != "$$"
        then
            if test_yes KILL_ECHO
            then
                local PID_INFO="`ps -f --no-heading $CHECK_PID`"
                test -n "$PID_INFO" && echo_line "PID $CHECK_PID killed:     <$PID_INFO>" || echo_line "PID $CHECK_PID already killed"
            fi
            kill -9 "$CHECK_PID" 2>/dev/null
        else
            echo_line "PID $CHECK_PID skipping killing itself"
        fi
    done
}

function kill_tree_name
# $1 regexp for process name
# $2 exclude PIDs
{
    local PID_LIST="`get_pids "$1"`"
    test_yes KILL_ECHO && echo_line "PIDs for name `echo_quote "$1"`: "$PID_LIST
    test -n "$2" && PID_LIST="`command echo "$PID_LIST" | $GREP --invert-match "$2"`"
    test -n "$PID_LIST" && kill_tree $PID_LIST
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
function perf_start
{
    local PERF_VAR="${1:-default}"
    shift
    PERF_MSG[$PERF_VAR]="$@"
    test -n "${PERF_MSG[$PERF_VAR]}" && local MSG=" \"${PERF_MSG[$PERF_VAR]}\""
    PERF_DATA[$PERF_VAR]="`date "+%s.%N"`"
    echo_line "Performance$MSG started on date `date +"%Y-%m-%d %H:%M:%S"` time: ${PERF_DATA[$PERF_VAR]}"
}

function perf_now
{
    local PERF_VAR="${1:-default}"
    local PERF_DATA_NOW="`date "+%s.%N"`"
    test -n "${PERF_MSG[$PERF_VAR]}" && local MSG=" \"${PERF_MSG[$PERF_VAR]}\""
    echo_line "Performance$MSG on date `date +"%Y-%m-%d %H:%M:%S"` time: $PERF_DATA_NOW elapsed: `command echo | $AWK "{ print $PERF_DATA_NOW - ${PERF_DATA[$PERF_VAR]}; }"`s"
}

function perf_end
{
    local PERF_VAR="${1:-default}"
    local PERF_DATA_NOW="`date "+%s.%N"`"
    test -n "${PERF_MSG[$PERF_VAR]}" && local MSG=" \"${PERF_MSG[$PERF_VAR]}\""
    echo_line "Performance$MSG ended on date `date +"%Y-%m-%d %H:%M:%S"` time: $PERF_DATA_NOW elapsed: `command echo | $AWK "{ print $PERF_DATA_NOW - ${PERF_DATA[$PERF_VAR]}; }"`s"
    PERF_DATA[$PERF_VAR]=0
}
#NAMESPACE/misc/end

#NAMESPACE/test/start
function set_yes
# $1=yes
{
    let $1=yes
}

function set_no
# $1=no
{
    let $1=no
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
    test $# != 2 && echo_error_function "Wrong parameters count"

    command echo "$1" | $GREP --quiet --extended-regexp $IGNORE_CASE "$2"
    return $?
}

function test_str
# $1 string to test
# $2 regexp
{
    local IGNORE_CASE=""
    test "$1" = "-i" -o "$1" = "--ignore-case" && IGNORE_CASE="yes" && shift
    test $# != 2 && echo_error_function "Wrong parameters count"

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
    test $# != 2 && echo_error_function "Wrong parameters count"

    test -f "$2" || return 1

    $GREP --quiet --extended-regexp "$1" "$2"
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

    command echo "$CMD" | $GREP --extended-regexp --quiet "$1"
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
    CURSOR_COLUMN=$CURSOR_COLUMN-1
    test $CURSOR_COLUMN -gt 0 && tput cuf $CURSOR_COLUMN
}

function pipe_remove_color
# removes color control codes from pipe
{
    sed --regexp-extended \
        --expression="s/\x1B\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g" \
        --expression="s/\\\\033\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g"
}

function pipe_remove_lines
# removes new line codes from pipe
{
    $AWK '$0=="" { next; } { print; }' | tr '\n' ' ' | xargs
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

        if test "$CUT_TYPE" = "center"
        then
            local -i LENGTH_LEFT
            let LENGTH_LEFT="( $LENGTH_MAX - 3) / 2"
            local -i LENGTH_RIGHT
            let LENGTH_RIGHT="$LENGTH_MAX - $LENGTH_LEFT - 3"
            local -i START_RIGHT
            let START_RIGHT="$LENGTH_TOTAL - $LENGTH_RIGHT"
            #echo_debug_variable LENGTH_LEFT START_RIGHT LENGTH_RIGHT
            echo "${LINE:0:$LENGTH_LEFT}...${LINE:$START_RIGHT}"
        elif test "$CUT_TYPE" = "left"
        then
            local -i LENGTH_RIGHT
            let LENGTH_RIGHT="$LENGTH_MAX - 3"
            local -i START_RIGHT
            let START_RIGHT="$LENGTH_TOTAL - $LENGTH_RIGHT"
            #echo_debug_variable START_RIGHT LENGTH_RIGHT
            echo "...${LINE:$START_RIGHT}"
        elif test "$CUT_TYPE" = "right"
        then
            local -i LENGTH_LEFT
            let LENGTH_LEFT="$LENGTH_MAX - 3"
            #echo_debug_variable LENGTH_LEFT
            echo "${LINE:0:$LENGTH_LEFT}..."
        fi
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

LOG_FILE=""
LOG_WITHDATE="yes"
LOG_DATE="%Y-%m-%d %H:%M:%S"
LOG_SECTION="=============================================================================="
LOG_SPACE=""
LOG_START="`date -u +%s`"

function log_file_init
{
    log_init "$@"
}

function log_init
{
    local LOG_TITLE="$0 - Log init"

    while test $# -gt 0
    do
        test "${1:0:1}" = "/" && LOG_FILE="$1" || LOG_TITLE="${1:-$LOG_TITLE}"
        shift
    done
    test -z "$LOG_FILE" && LOG_FILE="${SCRIPT_FILE_NOEXT}.log"

    file_prepare "$LOG_FILE"
    command echo "$LOG_SECTION" >> "$LOG_FILE"
    echo_log "`uname -n`: $LOG_TITLE"
}

function log_file_done
{
    log_done "$@"
}

function log_done
{
    local LOG_TITLE="$0 - Log done"
    test $# -eq 2 && LOG_TITLE="$1" && shift
    test -z "$LOG_FILE" && echo_error_function "Log file is not specified"

    local LOG_DURATION
    let LOG_DURATION=`date -u +%s`-$LOG_START

    file_prepare "$LOG_FILE"
    command echo "`date +"$LOG_DATE"` $LOG_TITLE, script runtime $LOG_DURATION seconds" >> "$LOG_FILE"
    command echo "$LOG_SECTION" >> "$LOG_FILE"
}

function echo_log
# echoes arguments only to log file
{
    test -z "$LOG_FILE" && return

    local LOG_DATE_STRING=""
    test_str "$1" "^(-d|--date)$" && LOG_DATE_STRING="`date +"$LOG_DATE"`" shift
    test_yes "$LOG_WITHDATE" && LOG_DATE_STRING="`date +"$LOG_DATE"`"

    file_prepare "$LOG_FILE"
    #echo "${LOG_SPACE}$@" | sed --expression='s/\\n/\n                    /g' --expression='s/^/                    /g' >> "$LOG_FILE"
    command echo "${LOG_SPACE}${LOG_DATE_STRING} $@" | pipe_remove_color >> "$LOG_FILE"
    #command echo "${LOG_SPACE}${LOG_DATE_STRING} $@" >> "$LOG_FILE"
}

function log_output
{
    pipe_log
}

function pipe_log
# pipe with command echo_log
{
    local BACKUP_IFS="$IFS"
    IFS=''
    while read LINE
    do
        echo_log "$LINE"
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


function pipe_prefix
# pipe with pipe_echo and nice output
# command | show_output
# -c <command> | --command=<command>
# -p <prefix> | --prefix=<prefix>
{
    local PREFIX="$PIPE_PREFIX"
    test -n "$SHOW_OUTPUT_PREFIX" && PREFIX="$SHOW_OUTPUT_PREFIX"
    local HIDELINES="$PIPE_PREFIX_HIDELINES"
    test -n "$SHOW_OUTPUT_HIDELINES" && HIDELINES="$SHOW_OUTPUT_HIDELINES"
    local COMMAND="$PIPE_PREFIX_COMMAND"
    test -n "$SHOW_OUTPUT_COMMAND" && HIDELINES="$SHOW_OUTPUT_COMMAND"
    local NEW_LINE="yes"

    check_arg_init
    while test $# -gt 0
    do
        check_arg_loop
        check_arg_value "p|prefix" "PREFIX" "$@"
        check_arg_value "c|command" "COMMAND" "$@"
        check_arg_switch "l|newline" "NEW_LINE|no" "$@"
        check_arg_shift && shift $CHECK_ARG_SHIFT && continue
        test -z "$HIDELINES" && HIDELINES="$1" && shift && continue
        echo_error_function "Unknown argument: $1" $ERROR_CODE_DEFAULT
    done
    check_arg_done

    #while read LINE
    #do
    #    echo "$PREFIX$LINE"
    #done

    $AWK --assign=prefix="$PREFIX" --assign=hideline="$HIDELINES" --assign=command="$COMMAND" --assign=newline="$NEW_LINE" '
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

        newline=="no" && $0=="" { next; }
        hideline!="" && current~hideline { next; }
        current==line { count++; next; }
        count==0 { line=current; count++; next; }
        count==1 { print prefix line; line=current; count=1; next; }
        count>1 { print prefix line " ("count"x)"; line=current; count=1; next; }
        END { if (count>1) p=" ("count"x)"; else p=""; print prefix line p; }' | pipe_echo
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
    local CHECK_NEEDQUOTE=".*[*;() \"'].*"
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
    echo_log "$ECHO_PREFIX$ECHO_UNAME$@"
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

    echo_log "$ECHO_PREFIX$ECHO_UNAME$TITLE_HEAD"
    echo_log "$ECHO_PREFIX$ECHO_UNAME$TITLE_MSG"
    echo_log "$ECHO_PREFIX$ECHO_UNAME$TITLE_TAIL"
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

    echo_log "$ECHO_PREFIX$ECHO_UNAME$@"
    return 0
}

function echo_step
{
    local -i STEP_NUMBER=""
    local STEP_NUMBER_STR=""
    if test $# -ge 2
    then
        STEP_VARIABLE="$1"
        shift
        STEP_NUMBER=${!STEP_VARIABLE}
        STEP_NUMBER_STR="${STEP_NUMBER}. "
    fi

    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_STEP$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@$COLOR_RESET"
        command echo -e "$COLOR_RESET\c"
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@"
    fi

    echo_log "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@"

    test_integer "$STEP_NUMBER" && let STEP_NUMBER++ && let $STEP_VARIABLE=$STEP_NUMBER
    test_str "$STEP_NUMBER" "^[a-z]$" && declare -x $STEP_VARIABLE="`command echo "$STEP_NUMBER" | tr "a-z" "b-z_"`"
    test_str "$STEP_NUMBER" "^[A-Z]$" && declare -x $STEP_VARIABLE="`command echo "$STEP_NUMBER" | tr "A-Z" "B-Z_"`"
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

    echo_log "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_SUBSTEP$@"
    return 0
}

function debug_init
{
    # in order to speed up script start, namespaces are init in echo_error_function / echo_debug_function
    #debug_init_namespaces
    set_no DEBUG_INIT_NAMESPACES
    return 0
}

function debug_init_namespaces
{
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
}

function debug_set
{
    test $# = 0 && local OPTIONS="debug" || local OPTIONS="$@"

    local OPTION
    for OPTION in $OPTIONS
    do
        #echo "$OPTION_DEBUG" | $GREP --quiet --word-regexp "$OPTION" || declare -x OPTION_DEBUG="$OPTION,$OPTION_DEBUG"
        #debug_unset $OPTION
        #test -n "$OPTION_DEBUG" && OPTION_DEBUG="$OPTION_DEBUG "
        #OPTION_DEBUG="$OPTION_DEBUG$OPTION"
        str_add_word OPTION_DEBUG "$OPTION"
    done
}

function debug_unset
{
    local OPTION="${1:-debug}"
    #OPTION_DEBUG="${OPTION_DEBUG/$OPTION?(,)/}"
    str_delete_word OPTION_DEBUG "$OPTION"
}

function debug_check
{
    local OPTION="${1:-debug}"
    #echo "$OPTION_DEBUG" | $GREP --quiet --word-regexp "$OPTION"
    test_str "$OPTION_DEBUG" "\b$OPTION\b"
}

function debug_level_check
{
    test_integer "$1" && return 0
    test -z "$1" && return 1
    local I="${DEBUG_LEVELS[$1]}"
    test_integer "$I" && return 0 || return 1
}

function debug_level_parse
{
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
            DEBUG_LEVEL_PARSE[0]=""
            DEBUG_LEVEL_PARSE[1]=""
        elif test_integer "$1"
        then
            local S
            for S in ${!DEBUG_LEVELS[@]}
            do
                test "$1" = "${DEBUG_LEVELS[$S]}" && DEBUG_LEVEL_PARSE[0]=$1 && DEBUG_LEVEL_PARSE[1]="$S" && return 0
            done
            DEBUG_LEVEL_PARSE[0]=$1
            DEBUG_LEVEL_PARSE[1]=""
        else
            local I="${DEBUG_LEVELS[$1]}"
            test_integer "$I" || echo_error_function "Unknown error level \"$1\""
            DEBUG_LEVEL_PARSE[0]=$I
            DEBUG_LEVEL_PARSE[1]="$1"
        fi
        return 0
    fi
    if test $# = 2
    then
        test_integer "$1" || echo_error_function "Wrong error level \"$1\""
        DEBUG_LEVEL_PARSE[0]=$1
        DEBUG_LEVEL_PARSE[1]="$2"
        return 0
    fi
}

function debug_level_set
{
    debug_level_parse "$@"
    DEBUG_LEVEL=${DEBUG_LEVEL_PARSE[0]}
    DEBUG_LEVEL_STR="${DEBUG_LEVEL_PARSE[1]}"
}

function debug_level_set_default
# default level for echo_debug without parameter
{
    debug_level_parse "$@"
    DEBUG_LEVEL_DEFAULT=${DEBUG_LEVEL_PARSE[0]}
    DEBUG_LEVEL_DEFAULT_STR="${DEBUG_LEVEL_PARSE[1]}"
}

function echo_debug_custom
# $1 debug string to be compared to OPTION_DEBUG
{
    if debug_check "$1"
    then
        shift
        local ECHO_DEBUG_LEVEL
        if test $# -ge 2 -a "$1" != "--"
        then
            debug_level_parse "$1"
            local LEVEL=${DEBUG_LEVEL_PARSE[0]}
            test -n "${DEBUG_LEVEL_PARSE[1]}" && ECHO_DEBUG_LEVEL="[${DEBUG_LEVEL_PARSE[1]}] "
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
                command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_DEBUG$ECHO_DEBUG_LEVEL$@$COLOR_RESET" > $REDIRECT_DEBUG
            else
                command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$ECHO_DEBUG_LEVEL$@" > $REDIRECT_DEBUG
            fi

            echo_log --date "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$ECHO_DEBUG_LEVEL$@"
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
    if debug_check variable
    then
        local LEVEL=""
        debug_level_check "$1" && LEVEL="$1" && shift

        local VAR_LIST=""
        while test $# -gt 0
        do
            local VAR_NAME="$1"
            shift
            test -n "$VAR_LIST" && VAR_LIST="$VAR_LIST "
            VAR_LIST="${VAR_LIST}${VAR_NAME}=\"${!VAR_NAME}\""
        done
        echo_debug_custom variable $LEVEL "$VAR_LIST"
    fi
    return 0
}

function echo_debug_function
{
    if debug_check function
    then
        local LEVEL=""
        debug_level_check "$1" && LEVEL="$1" && shift

        #FUNCTION_INFO="${FUNCNAME[@]}"
        #FUNCTION_INFO="${FUNCTION_INFO/echo_debug_function /}"
        #FUNCTION_INFO="${FUNCTION_INFO// / < }"
        #test "$FUNCTION_INFO" = "main" && FUNCTION_INFO="main "
        #FUNCTION_INFO="${FUNCTION_INFO/main/$SCRIPT_NAME}"
        #echo_quote "$@" > /dev/null
        #FUNCTION_INFO="${FUNCTION_INFO/ /($ECHO_QUOTE) }"

        test_no "$DEBUG_INIT_NAMESPACES" && debug_init_namespaces

        local F
        echo_quote "$@" > /dev/null
        F="${FUNCNAME[1]}"
        test -n "${FUNCTION_NAMESPACES[$F]}" && F="${FUNCTION_NAMESPACES[$F]}"
        FUNCTION_INFO="$F($ECHO_QUOTE)"
        for F in "${FUNCNAME[@]:2}"
        do
            test -n "${FUNCTION_NAMESPACES[$F]}" && F="${FUNCTION_NAMESPACES[$F]}"
            FUNCTION_INFO="$FUNCTION_INFO < $F"
        done

        FUNCTION_INFO="<<< $FUNCTION_INFO"

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
    if debug_check right
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
        let SHIFT_MESSAGE="$SHIFT_MESSAGE-${#DEBUG_MESSAGE_STR}"

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

        echo_log --date "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$@"
    fi
    return 0
}

function echo_error
{
    local EXIT_CODE=""
    local ECHO_ERROR="$@"
    test_integer "${@:(-1)}" && local EXIT_CODE=$2 && ECHO_ERROR="${@:1:${#@}-1}"

    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_ERROR$ECHO_PREFIX_ERROR$ECHO_ERROR!$COLOR_RESET" >&$REDIRECT_ERROR
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_ERROR$ECHO_ERROR!" >&$REDIRECT_ERROR
    fi

    echo_log "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_ERROR$ECHO_ERROR!"

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

    test_no "$DEBUG_INIT_NAMESPACES" && debug_init_namespaces

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

    echo_log "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_WARNING$ECHO_WARNING."

    test -n "$EXIT_CODE" && exit $EXIT_CODE
    return 0
}

# __HISTORY_FUNCTIONS_START__
function history_init
# [$1] history file
{
    shopt -u histappend
    if test -z "$1"
    then
        HISTFILE="${SCRIPT_FILE_NOEXT}.history"
    else
        declare -x HISTFILE="$1"
    fi
    declare -x HISTCMD=1001
    declare -x HISTCONTROL=ignoredups
    declare -x HISTSIZE=1000
    declare -x HISTFILESIZE=1000
    touch "$HISTFILE"
    #set -o history

    history_restore
}

function history_restore
{
    history -r

    declare -a HISTORY=()
    while read LINE
    do
        test -n "$LINE" && HISTORY+=("$LINE")
    done <<< "`tac "$HISTFILE"`"
}

function history_store
# $1 store item into history (if is not empty and same as previous)
{
    test -z "$1" -o "$1" = "${HISTORY[0]}" && return 0

    HISTORY=("$1" "${HISTORY[@]}")
    command echo "$1" >> "$HISTFILE"
    history -s "$1"
}
# __HISTORY_FUNCTIONS_END__

function colors_init
{
    # set colors to current terminal
    #echo "Initial color usage is set to $OPTION_COLOR and using $OPTION_COLORS colors"

# echo $TERM
# ok xterm/rxvt/konsole/linux
# no dumb/sun

    # set TERM if is not set
    test -z "$TERM" -a -n "$OPTION_TERM" && declare -x TERM="$OPTION_TERM"

    # init color numbers
    test_integer "$OPTION_COLORS" || OPTION_COLORS="256"

    # init color usage if is not set
    if ! test_yes "$OPTION_COLOR" && ! test_no "$OPTION_COLOR"
    then
        if test "`command echo "$TERM" | cut -c 1-5`" = "xterm" -o "$TERM" = "rxvt" -o "$TERM" = "konsole" -o "$TERM" = "linux" -o "$TERM" = "putty"
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

function check_arg_tools
{
    check_arg_switch "|ignore-unknown" "OPTION_IGNORE_UNKNOWN|yes" "$@"
    check_arg_switch "|debug" "" "$@" && debug_set debug
    check_arg_switch "|debug-variable" "" "$@" && debug_set variable
    check_arg_switch "|debug-function" "" "$@" && debug_set function
    check_arg_switch "|debug-command" "" "$@" && debug_set command
    check_arg_switch "|debug-right" "" "$@" && debug_set right
    check_arg_value "|debug-level" "DEBUG_LEVEL|ALL" "$@" && debug_level_set $DEBUG_LEVEL
    check_arg_value "|term" "OPTION_TERM|xterm" "$@"
    check_arg_value "|prefix" "OPTION_PREFIX|yes" "$@"
    check_arg_value "|color" "OPTION_COLOR|yes" "$@"
    check_arg_value "|no-color" "OPTION_COLOR|no" "$@"
    check_arg_value "|uname" "OPTION_UNAME|yes" "$@"
}

function tools_init
{
    check_arg_init
    while test $# -gt 0
    do
        check_arg_loop
        check_arg_tools "$@"
        check_arg_shift && shift $CHECK_ARG_SHIFT && continue
        if test -z "$TOOLS_FILE" -a -f "$1"
        then
            test -f "$1" && TOOLS_FILE="$1"
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
    check_arg_done

    SCRIPT_FILE="`readlink --canonicalize "$0"`"
    SCRIPT_FILE_NOEXT="${SCRIPT_FILE_NOEXT%.sh}"
    SCRIPT_FILE_NOEXT="${SCRIPT_FILE%.}"
    SCRIPT_NAME="`basename "$0"`"
    SCRIPT_FILE_NOEXT="${SCRIPT_NAME_NOEXT%.sh}"
    SCRIPT_FILE_NOEXT="${SCRIPT_NAME%.}"
    SCRIPT_DIR="`dirname "$SCRIPT_FILE"`"

    test -z "$TOOLS_FILE" -a -f "`dirname $0`/tools.sh" && TOOLS_FILE="`dirname $0`/tools.sh"
    TOOLS_FILE="`readlink --canonicalize "$TOOLS_FILE"`"
    TOOLS_NAME="`basename "$TOOLS_FILE"`"
    TOOLS_DIR="`dirname "$TOOLS_FILE"`"

    debug_level_set ALL
}

### tools exports

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

declare -x -r S_TAB="`command echo -e "\t"`"
declare -x -r S_NEWLINE="`command echo -e "\n"`"

declare -x -f str_trim
declare -x -f str_add_word
declare -x -f str_delete_word

declare -x PARSE_URL
declare -x PARSE_URL_PROTOCOL
declare -x PARSE_URL_USER_HOST
declare -x PARSE_URL_USER
declare -x PARSE_URL_HOST
declare -x PARSE_URL_FILE
declare -x -f str_parse_url

declare -x -a PARSE_ARGS=()
declare -x -f str_parse_args
declare -x -f str_get_arg
declare -x -f str_get_arg_from

declare -x -a CHECK_ARG_SHIFTS=()
declare -x -i CHECK_ARG_SHIFTS_I=0
declare -x -i CHECK_ARG_SHIFT=0
declare -x -f check_arg_init
declare -x -f check_arg_done
declare -x -f check_arg_loop
declare -x -f check_arg_shift
declare -x -f check_arg_switch
declare -x -f check_arg_value

declare -x -f file_temporary_name
declare -x -f file_delete
declare -x -f file_prepare;     declare -x -f prepare_file

declare -x    FILE_REMOTE
declare -x -f file_remote_get
declare -x -f file_remote_put

declare -x -f file_line_remove_local
declare -x -f file_line_add_local
declare -x -f file_line_set_local
declare -x -f file_line

declare -x -f file_config_set
declare -x -f file_config_get
declare -x -f file_config_read
declare -x -f file_replace

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

declare -x CALL_COMMAND_DEFAULT_USER=""
declare -x -f call_command

declare -x -f get_pids
declare -x    KILL_ECHO="yes"
declare -x -f kill_tree_verbose
declare -x -f kill_tree
declare -x -f kill_tree_name

declare -x -f fd_check
declare -x -f fd_find_free

declare -x -A PERF_DATA
declare -x -A PERF_MSG
#PERF_DATA["default"]=0
declare -x -f perf_start
declare -x -f perf_now
declare -x -f perf_end

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

declare -x -f pipe_remove_color
declare -x -f pipe_from
declare -x -f pipe_cut
declare -x -f echo_cut

declare -x PIPE_PREFIX="  >  "
declare -x PIPE_PREFIX_HIDELINES="" # regexp to hide lines
declare -x PIPE_PREFIX_COMMAND=""
declare -x PIPE_PREFIX_DEDUPLICATE="yes" ### !!!TODO!!!

declare -x -f log_init;         declare -x -f log_file_init
declare -x -f log_done;         declare -x -f log_file_done
declare -x -f echo_log

declare -x -f pipe_log;         declare -x -f log_output
declare -x -f pipe_echo;        declare -x -f echo_output
declare -x -f pipe_prefix
declare -x -f pipe_echo_prefix; declare -x -f show_output

declare -x ECHO_QUOTE
declare -x -f echo_quote
declare -x -f echo_line
declare -x -f echo_title
declare -x -f echo_info
declare -x -f echo_step
declare -x -f echo_substep

declare -x -f debug_init
declare -x    DEBUG_INIT_NAMESPACES="no"
declare -x -f debug_init_namespaces
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
declare -x -f debug_set
declare -x -f debug_unset
declare -x -f debug_check
declare -x -f debug_level_check
declare -x -a DEBUG_LEVEL_PARSE
declare -x -f debug_level_parse
declare -x -f debug_level_set
declare -x -f debug_level_set_default
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

declare -x -f history_init
declare -x -f history_restore
declare -x -f history_store

declare -x OPTION_IGNORE_UNKNOWN="no"
declare -x -f check_arg_tools
declare -x -f tools_init
declare -x -f colors_init

### tools init
tools_init "$@"
debug_init
colors_init

# set echo prefix or uname prefix
test_yes OPTION_PREFIX && ECHO_PREFIX="### " || ECHO_PREFIX=""
test -n "$ECHO_PREFIX" && ECHO_PREFIX_C="$COLOR_PREFIX$ECHO_PREFIX$COLOR_RESET"
test_yes OPTION_UNAME && ECHO_UNAME="`uname -n`: " || ECHO_UNAME=""
test -n "$ECHO_UNAME" && ECHO_UNAME_C="$COLOR_UNAME$ECHO_UNAME$COLOR_RESET"

return 0
