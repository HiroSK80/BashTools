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

export TOOLS_LOADED="yes"

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
    export RM="rm"
    export AWK="/usr/bin/nawk"
    export GREP="/usr/xpg4/bin/grep"
    export SSH="ssh -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SSHq="$SSH -q"
    export SCP="scp -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SCPq="$SCP -q"
fi
if test "$UNIX_TYPE" = "Linux"
then
    export RM="/bin/rm -f"
    export AWK="/bin/awk"
    type awk > /dev/null 2>&1 && export AWK="`type -P awk`"
    export GREP="/bin/grep"
    type grep > /dev/null 2>&1 && export GREP="`type -P grep`"
    #export SSH="ssh -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SSH="ssh -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SSHbq="ssh -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SSHq="$SSH -q"
    export SSHbq="$SSHb -q"
    #export SCP="scp -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SCP="scp -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SCPb="scp -o BatchMode=yes -o ConnectTimeout=5 -o GSSAPIAuthentication=no"
    export SCPq="$SCP -q"
    export SCPbq="$SCPb -q"
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

function assign
{
    #export -n "$1"+="$2" !!!WHY?!!!
    printf -v "$1" '%s' "$2"
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
        test -n "$ARG_NAME_VAR" && export ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
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
            test -n "${ARG_NAME_VAR}" && export ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
            CHECK_ARG_SHIFT+=1 && return 0 #echo_error "Missing value for argument \"$1\"" $OPTION_DEFAULT_ERROR_CODE
        elif test "${2:0:1}" != "-"
        then
            test -n "${ARG_NAME_VAR}" && export ${ARG_NAME_VAR}="$2"
            CHECK_ARG_SHIFT+=1
        else
            export ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
        fi
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    if test "${1%%=*}" = "--$ARG_NAME_LONG"
    then
        export ${ARG_NAME_VAR}="${1#*=}"
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    return 1
}

function str_parse_url
# $1 URL
#   [path/]filename
#   host:[path/]filename
#   user@host:[path/]filename
#   protocol://user@host:[path/]filename
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
    echo "PARSE_URL=$PARSE_URL"
    echo "PARSE_URL_PROTOCOL=$PARSE_URL_PROTOCOL"
    echo "PARSE_URL_USER_HOST=$PARSE_URL_USER_HOST"
    echo "PARSE_URL_HOST=$PARSE_URL_HOST"
    echo "PARSE_URL_USER=$PARSE_URL_USER"
    echo "PARSE_URL_FILE=$PARSE_URL_FILE"
}

# __FILE_FUNCTIONS_START__
function file_delete
{
    if test -f "$1"
    then
        $RM "$1"
        test -f "$1" && echo_error_function "Can't delete `echo_quote "$1"` file" $OPTION_DEFAULT_ERROR_CODE
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
        echo_error_function "Unknown argument: $1" $OPTION_DEFAULT_ERROR_CODE
    done
    check_arg_done
    test -z "$FILE" && echo_error_function "Filename is not specified" $OPTION_DEFAULT_ERROR_CODE

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
    test -w "$FILE" || echo_error_function "Can't create and prepare file for writting: `echo_quote $FILE`" $OPTION_DEFAULT_ERROR_CODE

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
    local FILE="${2#*:}"
    export FILE_REMOTE="/tmp/file_remote_`basename "$FILE"`.$$"
    test -n "$2" && FILE_REMOTE="$2"
    file_delete "$FILE_REMOTE"
    $SCPq "$SSH":"$FILE" "$FILE_REMOTE" || return 1
}

function file_remote_put
# $1 user@host:remote_file
# $2 local file
{
    local SSH="${1%%:*}"
    local FILE="${2#*:}"
    export FILE_REMOTE="/tmp/file_remote_`basename "$FILE"`.$$"
    test -n "$3" && FILE_REMOTE="$3"
    $SCPq "$FILE_REMOTE" "$SSH":"$FILE" || return 1
    file_delete "$FILE_REMOTE"
}

function file_line_remove_local
# $1 filename
# $2 remove regexp
{
    local FILE="$1"
    local TEMP_FILE="/tmp/`basename "$FILE"`.tmp"
    local REGEXP="$2"
    local ERROR_MSG="Remove line \"$REGEXP\" from file `echo_quote "$FILE"` fail"
    if test -r "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
        if diff "$FILE" "$TEMP_FILE" > /dev/null 2> /dev/null
        then
            cat "$TEMP_FILE" 2> /dev/null | $GREP --invert-match "$REGEXP" > "$FILE" 2> /dev/null
            file_delete "$TEMP_FILE"
        else
            file_delete "$TEMP_FILE"
            echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
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
    local TEMP_FILE="/tmp/`basename "$FILE"`.tmp.$$"
    local LINE="$2"
    local REGEXP_AFTER="$3"
    local REGEXP_REPLACE="$4"
    local ERROR_MSG="Add line \"$LINE\" to file `echo_quote "$FILE"` fail"

    test -e "$FILE" || touch "$FILE"

    if test -z "$REGEXP_AFTER$REGEXP_REPLACE"
    then
        command echo "$LINE" >> "$FILE" || echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
    else
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
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
            echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
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
    test_str "$LINE" "(remove|add|set)" || echo_error_function "Supported only line: remove add set functions and not: $LINE" $OPTION_DEFAULT_ERROR_CODE
    str_parse_url "$2"
    shift 2
    if test "$PARSE_URL_PROTOCOL" = "file" || is_localhost "$PARSE_URL_HOST"
    then
        file_line_${LINE}_local "$PARSE_URL_FILE" "$@"
    else
        file_remote_get "$PARSE_URL" || echo_error_function "Can't retrieve `echo_quote "$PARSE_URL_FILE"` file from $PARSE_URL_USER_HOST" $OPTION_DEFAULT_ERROR_CODE
        #ls -la "$FILE_REMOTE"
        file_line_${LINE}_local "$FILE_REMOTE" "$@"
        #ls -la "$FILE_REMOTE"
        file_remote_put "$PARSE_URL"
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
    local CONFIG_TEMP_FILE="/tmp/`basename "$CONFIG_FILE"`.tmp"
    local OPTION_SECTION="`dirname "$2"`"
    local OPTION_NAME="`basename "$2"`"
    local VALUE="$3"
    local ERROR_MSG="Configuration \"$OPTION_NAME=\"$VALUE\"\" change to file `echo_quote "$CONFIG_FILE"` fail"
    if test -e "$CONFIG_FILE"
    then
        cat "$CONFIG_FILE" > "$CONFIG_TEMP_FILE" || echo_error_function "$ERROR_MSG, temporary file create `echo_quote "$CONFIG_TEMP_FILE"` problem" $OPTION_DEFAULT_ERROR_CODE
        test -w "$CONFIG_FILE" || echo_error_function "$ERROR_MSG, file not writable" $OPTION_DEFAULT_ERROR_CODE
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
            echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
        fi
    else
        if test "$OPTION_SECTION" = "."
        then
            echo "$OPTION_NAME=\"$VALUE\"" > "$CONFIG_FILE" || echo_error_function "$ERROR_MSG, file create problem" $OPTION_DEFAULT_ERROR_CODE
        else
            echo "[$OPTION_SECTION]" > "$CONFIG_FILE" || echo_error_function "$ERROR_MSG, file create problem" $OPTION_DEFAULT_ERROR_CODE
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
    test_str "$1" "(-e|--eval)" && DO_EVAL="yes" && shift
    test_str "$1" "(-n|--noeval)" && DO_EVAL="no" && shift

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

    test "$OPTION_SECTION" != "." && export ${OPTION_SECTION}_${OPTION_NAME}="$VALUE"
    export $OPTION_NAME="$VALUE"
}

function file_replace
# $1 filename
# $2 search
# $3 replace
{
    local FILE="$1"
    local TEMP_FILE="/tmp/`basename "$FILE"`.tmp"
    local SEARCH="$2"
    local REPLACE="$3"
    local ERROR_MSG="File `echo_quote "$FILE"` string \"$SEARCH\" replace fail"
    if test -e "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE" || echo_error_function "$ERROR_MSG, temporary file create `echo_quote "$TEMP_FILE"` problem" $OPTION_DEFAULT_ERROR_CODE
        cat "$TEMP_FILE" | sed --expression="s|$SEARCH|$REPLACE|g" > "$FILE" || echo_error_function "$ERROR_MSG" $OPTION_DEFAULT_ERROR_CODE
        file_delete "$TEMP_FILE"
    fi
}
# __FILE_FUNCTIONS_END__

# __NETWORK_FUNCTIONS_START__
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
# __NETWORK_FUNCTIONS_END__

function call_command
{
    local HOST=""
    local TOPT="-t"
    local USER="$CALL_COMMAND_DEFAULT_USER"
    local USER_SET="no"
    local LOCAL_DEBUG="no"
    check_debug && LOCAL_DEBUG="yes"
    check_debug right && LOCAL_DEBUG="right"
    while test $# -gt 0
    do
        test "$1" = "--debug" && LOCAL_DEBUG="yes" && shift && continue
        test "$1" = "--debug-right" && LOCAL_DEBUG="right" && shift && continue
        test "$1" = "--nodebug" && LOCAL_DEBUG="no" && shift && continue
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
        test_yes "$LOCAL_DEBUG" && echo_debug 1 "$COMMAND_STRING"
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
        test_yes "$LOCAL_DEBUG" && echo_debug 1 "$SSH $TOPT $USER_SSH$HOST \"$COMMAND_STRING\""
        test "$LOCAL_DEBUG" = "right" && echo_debug_right "$SSH $TOPT $USER_SSH$HOST \"$COMMAND_STRING\""
        $SSH $TOPT $USER_SSH$HOST "$@"
        EXIT_CODE=$?
    fi

    return $EXIT_CODE
}

function get_pids
{
    ps -ef | $GREP --invert-match $$ | $AWK --assign=p="$1" --assign=s="$$" '$3==s { next; } $0~p { print $2; }'
}

export ECHO_KILL="no"
function kill_tree_childs
{
    local TOPMOST="$1"
    local CHECK_PID=$2
    CHILD_PIDS="`ps -o pid --no-headers --ppid ${CHECK_PID}`"
    for CHILD_PID in $CHILD_PIDS
    do
        kill_tree_childs "yes" "$CHILD_PID"
    done
    if test_yes TOPMOST && test "$CHECK_PID" != "$$"
    then
        local FOUND_PID="`ps -ef | $AWK --assign p="$CHECK_PID" '$2==p { print "yes"; }'`"
        if test_yes ECHO_KILL
        then
            test_yes FOUND_PID \
                && ps -ef | $AWK --assign p="$CHECK_PID" '$2==p { print "PID " p " killed: " $0; }' | echo_output \
                || echo_line "PID $CHECK_PID already killed" | echo_output
        fi
        kill -9 "$CHECK_PID" 2>/dev/null
    fi
}

function kill_tree
{
    for I in $*
    do
        kill_tree_childs "yes" $I
    done
}

function kill_tree_name
# $1 regexp for process name
# $2 exclude PIDs
{
    local PID_LIST="`get_pids "$1"`"
    test -n "$2" && PID_LIST="`command echo "$PID_LIST" | $GREP --invert-match $2`"
    kill_tree $PID_LIST
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

function command_options
{
    local TASK="$1"
    shift
    if test "$TASK" = "fill"
    then
        export COMMAND="$1"
        export OPTIONS="$2 $3 $4 $5 $6 $7 $8 $9"
        export OPTIONS2="$3 $4 $5 $6 $7 $8 $9 ${10}"
        export OPTIONS3="$4 $5 $6 $7 $8 $9 $10 ${11}"
        export OPTIONS4="$5 $6 $7 $8 $9 $10 $11 ${12}"
        export OPTION="$2"
        export OPTION1="$2"
        export OPTION2="$3"
        export OPTION3="$4"
        export OPTION4="$5"
        export OPTION5="$6"
        export OPTION6="$7"
        export OPTION7="$8"
        export OPTION8="$9"
        export OPTION9="${10}"
        unset OPTIONS_A
        declare -a OPTIONS_A=("$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}")
    fi
    if test "$TASK" = "parse"
    then
        export COMMAND="`str_get_arg "$INPUT" 1`"
        export OPTIONS="`str_get_arg_from "$INPUT" 2`"
        export OPTIONS2="`str_get_arg_from "$INPUT" 3`"
        export OPTIONS3="`str_get_arg_from "$INPUT" 4`"
        export OPTIONS4="`str_get_arg_from "$INPUT" 5`"
        export OPTION="`str_get_arg "$INPUT" 2`"
        export OPTION1="`str_get_arg "$INPUT" 2`"
        export OPTION2="`str_get_arg "$INPUT" 3`"
        export OPTION3="`str_get_arg "$INPUT" 4`"
        export OPTION4="`str_get_arg "$INPUT" 5`"
        export OPTION5="`str_get_arg "$INPUT" 6`"
        export OPTION6="`str_get_arg "$INPUT" 7`"
        export OPTION7="`str_get_arg "$INPUT" 8`"
        export OPTION8="`str_get_arg "$INPUT" 9`"
        export OPTION9="`str_get_arg "$INPUT" 10`"
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


function set_yes
# $1=yes
{
    export $1=yes
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
    test -n "${1+ok}" && test_str_yes "${!1}" || return 1
}

function test_str_no
# $1 $1 test string for boolean no string
{
    [[ "$1" =~ ^(n|N|no|No|NO)$ ]]
}

function test_no
# $1 no string or variable
{
    test_str_no "$1" && return 0
    test -n "${1+ok}" && test_str_no "${!1}" || return 1
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
    test -z "$LOG_FILE" && LOG_FILE="`command echo "$0" | sed --regexp-extended --expression='s:(|\.|\.sh)$:.log:'`"

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
        echo_error_function "Unknown argument: $1" $OPTION_DEFAULT_ERROR_CODE
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
                        QUOTE="D"
                    else
                        QUOTE="S"
                    fi
                fi
            else # SINGLE or NONE
                QUOTE="D"
            fi

            if test "$QUOTE" = "D"
            then
                ARG="${ARG//\"/\\\\\"}"
                command echo -e "$SPACE\"$ARG\"\c"
            else
                command echo -e "$SPACE'$ARG'\c"
            fi
        else
            command echo -e "$SPACE$ARG\c"
        fi
        SPACE=" "
    done
    echo
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
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@"
    fi

    echo_log "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_STEP$STEP_NUMBER_STR$@"

    test_integer "$STEP_NUMBER" && let STEP_NUMBER++ && let $STEP_VARIABLE=$STEP_NUMBER
    test_str "$STEP_NUMBER" "^[a-z]$" && export $STEP_VARIABLE="`command echo "$STEP_NUMBER" | tr "a-z" "b-z_"`"
    test_str "$STEP_NUMBER" "^[A-Z]$" && export $STEP_VARIABLE="`command echo "$STEP_NUMBER" | tr "A-Z" "B-Z_"`"
    return 0
}

function echo_substep
{
    if test_yes "$OPTION_COLOR"
    then
        command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_SUBSTEP$ECHO_PREFIX_SUBSTEP$@$COLOR_RESET"
    else
        command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_SUBSTEP$@"
    fi

    echo_log "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_SUBSTEP$@"
    return 0
}

function set_debug
{
    test $# = 0 && local OPTIONS="yes" || local OPTIONS="$@"
    local OPTION
    for OPTION in $OPTIONS
    do
        echo "$OPTION_DEBUG" | $GREP --quiet --word-regexp "$OPTION" || export OPTION_DEBUG="$OPTION,$OPTION_DEBUG"
    done
}

function unset_debug
{
    local OPTION="${1:-yes}"
    OPTION_DEBUG="${OPTION_DEBUG/$OPTION?(,)/}"
}

function check_debug
{
    local OPTION="${1:-yes}"
    echo "$OPTION_DEBUG" | $GREP --quiet --word-regexp "$OPTION"
}

function parse_debug_level
{
#OPTION_DEBUGS[ALL]=100
#OPTION_DEBUGS[TRACE]=90
#OPTION_DEBUGS[DEBUG]=80
#OPTION_DEBUGS[INFO]=50
#OPTION_DEBUGS[WARN]=30
#OPTION_DEBUGS[ERROR]=20
#OPTION_DEBUGS[FATAL]=10
#OPTION_DEBUGS[OFF]=0
    if test -z "$1"
    then
        echo ""
        return 0
    elif test_integer "$1"
    then
        local S
        for S in ${!OPTION_DEBUGS[@]}
        do
            test "$1" = "${OPTION_DEBUGS[$S]}" && echo "$1 $S" && return 0
        done
        echo "$1"
    else
        local I="${OPTION_DEBUGS[$1]}"
        test_integer "$I" || echo_error_function "Unknown error level \"$1\""
        echo "$I $1"
    fi
}

function set_debug_level
{
    local LEVEL=( `parse_debug_level "$1"` )
    OPTION_DEBUG_LEVEL=${LEVEL[0]}
    OPTION_DEBUG_LEVEL_STR="${LEVEL[1]}"
}

function set_debug_level_default
# default level for echo_debug without parameter
{
    local LEVEL=( `parse_debug_level "$1"` )
    OPTION_DEBUG_LEVEL_DEFAULT=${LEVEL[0]}
    OPTION_DEBUG_LEVEL_DEFAULT_STR="${LEVEL[1]}"
}

function echo_debug
{
    if check_debug
    then
        if test $# -ge 2
        then
            local LEVEL_A=( `parse_debug_level "$1"` )
            local LEVEL=${LEVEL_A[0]}
            test -n "${LEVEL_A[1]}" && ECHO_DEBUG_LEVEL="[${LEVEL_A[1]}] "
            shift
        else
            local LEVEL=$OPTION_DEBUG_LEVEL_DEFAULT
            test -n "$OPTION_DEBUG_LEVEL_DEFAULT_STR" && ECHO_DEBUG_LEVEL="[$OPTION_DEBUG_LEVEL_DEFAULT_STR] " || ECHO_DEBUG_LEVEL=""
        fi
        if test $LEVEL -le $OPTION_DEBUG_LEVEL
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

function echo_debug_right
# -1 shift to previous line
# $@ message
{
    local SHIFT1="no"
    local SHIFT1_MIN_FREE="20"
    if check_debug right
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

function echo_debug_variable
{
    if check_debug variable
    then
        local VAR_LIST=""
        while test $# -gt 0
        do
            local VAR_NAME="$1"
            shift
            test -n "$VAR_LIST" && VAR_LIST="$VAR_LIST "
            VAR_LIST="${VAR_LIST}${VAR_NAME}=\"${!VAR_NAME}\""
        done
        if test_yes "$OPTION_COLOR"
        then
            command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_DEBUG$VAR_LIST$COLOR_RESET" > $REDIRECT_DEBUG
        else
            command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$VAR_LIST" > $REDIRECT_DEBUG
        fi
    fi
    return 0
}

function echo_debug_var
{
    echo_debug_variable "$@"
    return 0
}

function echo_debug_function
{
    if check_debug function
    then
        FUNCTION_INFO="${FUNCNAME[@]}"
        FUNCTION_INFO="${FUNCTION_INFO/echo_debug_funct /}"
        FUNCTION_INFO="${FUNCTION_INFO/echo_debug_function /}"
        FUNCTION_INFO="${FUNCTION_INFO// / < }"
        FUNCTION_INFO="${FUNCTION_INFO/ /($@) }"
        FUNCTION_INFO="<<< $FUNCTION_INFO"
        if test_yes "$OPTION_COLOR"
        then
            command echo -e "$ECHO_PREFIX_C$ECHO_UNAME_C$COLOR_DEBUG$FUNCTION_INFO$COLOR_RESET" > $REDIRECT_DEBUG
        else
            command echo "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$FUNCTION_INFO" > $REDIRECT_DEBUG
        fi

        echo_log --date "$ECHO_PREFIX$ECHO_UNAME$ECHO_PREFIX_DEBUG$FUNCTION_INFO"
    fi
    return 0
}

function echo_debug_funct
{
    echo_debug_function "$@"
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
    local ECHO_FUNCTION="${FUNCNAME[@]}"
    ECHO_FUNCTION="${ECHO_FUNCTION/echo_error_function /}"
    #ECHO_FUNCTION="${ECHO_FUNCTION/ */}"
    ECHO_FUNCTION="${ECHO_FUNCTION// / < }"
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

### history

function history_init
# [$1] history file
{
    shopt -u histappend
    test -z "$1" && export HISTFILE="$TOOLS_DIR/tools.history" || export HISTFILE="$1"
    export HISTCMD=1001
    export HISTCONTROL=ignoredups
    export HISTSIZE=1000
    export HISTFILESIZE=1000
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


function colors_init
{
    # set colors to current terminal
    #echo "Initial color usage is set to $OPTION_COLOR and using $OPTION_COLORS colors"

# echo $TERM
# ok xterm/rxvt/konsole/linux
# no dumb/sun

    # set TERM if is not set
    test -z "$TERM" -a -n "$OPTION_TERM" && export TERM="$OPTION_TERM"

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
    COLOR_SUBSTEP="$COLOR_WHITE"
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
    check_arg_switch "|debug" "" "$@" && set_debug yes
    check_arg_value "|debug-level" "OPTION_DEBUG_LEVEL|ALL" "$@" && set_debug_level $OPTION_DEBUG_LEVEL
    check_arg_switch "|debug-right" "" "$@" && set_debug right
    check_arg_switch "|debug-variable" "" "$@" && set_debug variable
    check_arg_switch "|debug-function" "" "$@" && set_debug function
    check_arg_value "|term" "OPTION_TERM|xterm" "$@"
    check_arg_value "|prefix" "OPTION_PREFIX|yes" "$@"
    check_arg_value "|color" "OPTION_COLOR|yes" "$@"
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

    TOOLS_FILE="`readlink --canonicalize "$TOOLS_FILE"`"
    TOOLS_NAME="`basename "$TOOLS_FILE"`"
    TOOLS_DIR="`dirname "$TOOLS_FILE"`"

    set_debug_level ALL
}

### tools exports

export REDIRECT_DEBUG=/dev/stderr
export REDIRECT_ERROR=/dev/stdout
export REDIRECT_WARNING=/dev/stdout

export OPTION_IGNORE_UNKNOWN="yes"

export OPTION_TERM="xterm" # default value if TERM is not set
export OPTION_DEBUG
export OPTION_PREFIX="no"
export OPTION_COLOR
export OPTION_COLORS
export OPTION_UNAME

export ECHO_PREFIX
export ECHO_PREFIX_STEP="  "
export ECHO_PREFIX_SUBSTEP="    - "
export ECHO_PREFIX_DEBUG="@@@ "
export ECHO_PREFIX_ERROR="Error: "
export ECHO_PREFIX_WARNING="Warning: "
export ECHO_UNAME

export COLOR_BLACK COLOR_BLACK_E
export COLOR_RESET COLOR_RESET_E
export COLOR_RED COLOR_RED_E
export COLOR_GREEN COLOR_GREEN_E
export COLOR_YELLOW COLOR_YELLOW_E
export COLOR_BLUE COLOR_BLUE_E
export COLOR_MAGENTA COLOR_MAGENTA_E
export COLOR_CYAN COLOR_CYAN_E
export COLOR_GRAY COLOR_GRAY_E
export COLOR_LIGHT_GRAY COLOR_LIGHT_GRAY_E

export COLOR_DARK_GRAY COLOR_DARK_GRAY_E
export COLOR_LIGHT_RED COLOR_LIGHT_RED_E
export COLOR_LIGHT_GREEN COLOR_LIGHT_GREEN_E
export COLOR_LIGHT_YELLOW COLOR_LIGHT_YELLOW_E
export COLOR_LIGHT_BLUE COLOR_LIGHT_BLUE_E
export COLOR_LIGHT_MAGENTA COLOR_LIGHT_MAGENTA_E
export COLOR_LIGHT_CYAN COLOR_LIGHT_CYAN_E
export COLOR_WHITE COLOR_WHITE_E

export COLOR_ORANGE COLOR_ORANGE_E
export COLOR_CHARCOAL COLOR_CHARCOAL_E

export TITLE_STYLE="+|+--+|+"
export TITLE_STYLE="########"
export TITLE_STYLE="[ [==] ]"
export COLOR_TITLE; export COLOR_TITLE_BORDER
export COLOR_INFO
export COLOR_STEP
export COLOR_SUBSTEP
export COLOR_DEBUG
export COLOR_ERROR
export COLOR_WARNING
export COLOR_UNAME
export COLOR_PREFIX

export -f query
export -f query_yn
export -f query_ny

declare -a PARSE_ARGS=()
export PARSE_ARGS=()
export -f str_parse_args
export -f str_get_arg
export -f str_get_arg_from

declare -a CHECK_ARG_SHIFTS=()
export CHECK_ARG_SHIFTS
declare -i CHECK_ARG_SHIFTS_I=0
export CHECK_ARG_SHIFTS_I
declare -i CHECK_ARG_SHIFT=0
export CHECK_ARG_SHIFT
export -f check_arg_init
export -f check_arg_done
export -f check_arg_loop
export -f check_arg_shift
export -f check_arg_switch
export -f check_arg_value

export PARSE_URL
export PARSE_URL_PROTOCOL
export PARSE_URL_USER_HOST
export PARSE_URL_USER
export PARSE_URL_HOST
export PARSE_URL_FILE
export -f str_parse_url

export -f file_delete
export -f file_prepare;     export -f prepare_file

export FILE_REMOTE
export -f file_remote_get
export -f file_remote_put

export -f file_line_remove_local
export -f file_line_add_local
export -f file_line_set_local
export -f file_line         #export -f file_line_add1 lr_file_line_add

export -f file_config_set
export -f file_config_get
export -f file_config_read
export -f file_replace

export -f check_ssh
export -f check_internet

export -f check_ping
export -f get_ip_arp
export -f get_ip_ping
export -f get_ip
export -f is_localhost
export -f get_id

export -f ssh_scanid
export -f ssh_scanremoteid
export -f ssh_exportid
export -f ssh_importid

export CALL_COMMAND_DEFAULT_USER=""
export -f call_command

export -f get_pids
export -f kill_tree_childs
export -f kill_tree
export -f kill_tree_name

export -f fd_check
export -f fd_find_free

declare -A PERF_DATA
declare -A PERF_MSG
#PERF_DATA["default"]=0
export -f perf_start
export -f perf_now
export -f perf_end

export -f set_yes

export -f command_options;  export -f fill_command_options # = command_options fill
                            export -f insert_cmd # = command_options insert

export S_TAB="`command echo -e "\t"`"
export S_NEWLINE="`command echo -e "\n"`"
export -f test_ne0
export -f test_boolean
export -f test_str_yes
export -f test_yes
export -f test_str_no
export -f test_no
export -f test_ok
export -f test_nok
export -f test_integer
export -f test_str;         export -f test_str_grep
export -f test_file
export -f test_cmd
export -f test_cmd_z
export -f test_opt
export -f test_opt2
export -f test_opt_z
export -f test_opt2_z
export -f test_opt_i
export -f test_opt2_i

declare CURSOR_POSITION="0;0"
export CURSOR_POSITION
declare -i CURSOR_COLUMN=0
export CURSOR_COLUMN
declare -i CURSOR_ROW=0
export CURSOR_ROW
export -f cursor_get_position
export -f cursor_move_down

export -f pipe_remove_color
export -f pipe_from
export -f pipe_cut
export -f echo_cut

export PIPE_PREFIX="  >  "
export PIPE_PREFIX_HIDELINES="" # regexp to hide lines
export PIPE_PREFIX_COMMAND=""
export PIPE_PREFIX_DEDUPLICATE="yes" ### !!!TODO!!!

export -f log_init;         export -f log_file_init
export -f log_done;         export -f log_file_done
export -f echo_log

export -f pipe_log;         export -f log_output
export -f pipe_echo;        export -f echo_output
export -f pipe_prefix
export -f pipe_echo_prefix; export -f show_output

export -f echo_quote
export -f echo_line
export -f echo_title
export -f echo_info
export -f echo_step
export -f echo_substep

export -f set_debug
export -f unset_debug
export -f check_debug

export OPTION_DEBUG_LEVEL
export OPTION_DEBUG_LEVEL_STR
export OPTION_DEBUG_LEVEL_DEFAULT=80
export OPTION_DEBUG_LEVEL_DEFAULT_STR=""
export ECHO_DEBUG_LEVEL
declare -A OPTION_DEBUGS
OPTION_DEBUGS[ALL]=100
OPTION_DEBUGS[TRACE]=90
OPTION_DEBUGS[DEBUG]=80
OPTION_DEBUGS[INFO]=50
OPTION_DEBUGS[WARN]=30
OPTION_DEBUGS[ERROR]=20
OPTION_DEBUGS[FATAL]=10
OPTION_DEBUGS[OFF]=0
export -f set_debug_level
export -f set_debug_level_default
export -f echo_debug
export -f echo_debug_right
export -f echo_debug_variable
export -f echo_debug_var
export -f echo_debug_function
export -f echo_debug_funct
export OPTION_DEFAULT_ERROR_CODE=99
export -f echo_error
export -f echo_error_ne0
export -f echo_error_function
export -f echo_error_exit
export -f echo_warning

# needed TOOLS_FILE / TOOLS_DIR initialized in case history_init without log file name specified
export -f history_init
export -f history_restore
export -f history_store

export -f colors_init


### tools init
tools_init "$@"

colors_init

# set echo prefix or uname prefix
test_yes OPTION_PREFIX && ECHO_PREFIX="### " || ECHO_PREFIX=""
test -n "$ECHO_PREFIX" && ECHO_PREFIX_C="$COLOR_PREFIX$ECHO_PREFIX$COLOR_RESET"
test_yes OPTION_UNAME && ECHO_UNAME="`uname -n`: " || ECHO_UNAME=""
test -n "$ECHO_UNAME" && ECHO_UNAME_C="$COLOR_UNAME$ECHO_UNAME$COLOR_RESET"

return 0
