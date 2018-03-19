#!/bin/bash

# execute as: ". <thisname> <thisname> [options]"
# example:
#       export TOOLS_FILE="`dirname $0`/tools.sh"
#       . "$TOOLS_FILE" "$TOOLS_FILE" --debug-right

# options:
# -prefix <prefix_string>
# -color yes|no
# -uname yes|no

export INCLUDE_TOOLS="yes"

#!/bin/bash

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
    export AWK="/usr/bin/nawk"
    export GREP="/usr/xpg4/bin/grep"
fi
if test "$UNIX_TYPE" = "Linux"
then
    export AWK="/bin/awk"
    type awk > /dev/null 2>&1 && export AWK="`type -P awk`"
    export GREP="/bin/grep"
    type grep > /dev/null 2>&1 && export GREP="`type -P grep`"
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
                OK="`echo "$REPLY" | awk '/'$TEST_REGEXP'/ { print "ok"; exit } { print "no" }'`"
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
    export -n "$1"+="$2"
}

function str_parse_args
# $1 string with arguments and options in ""
# !!! $2 destination array variable
{
    unset PARSE_ARGS

    local ARRAY="${2}"
    local EVAL="`printf '%q\n' "$1"`"
    EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:\`:_:g')"
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
    local EVAL="`printf '%q\n' "$1"`"
    EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:\`:_:g')"
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
    local EVAL="`printf '%q\n' "$1"`"
    EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\\":":g' --expression='s:\`:_:g')"
    #EVAL="$(echo "$EVAL" | sed --expression='s:\\ : :g' --expression='s:\`:_:g')"
    #echo_debug "$EVAL"

    eval "set -- $EVAL"
    #echo_debug "$@"
    echo "${@:$FROM}"
}

function check_arg_init
{
    CHECK_ARG_SHIFT=0
}

function check_arg_shift
{
    test $CHECK_ARG_SHIFT -ne 0
}

function check_arg_switch
# $1 short|long
# $2 variable
# $3 arguments
# usage: check_arg_switch "d|debug" "OPTION_DEBUG" "$@"
# example:
# while test $# -gt 0
# do
#     check_arg_init
#     check_arg_switch "d|debug" "OPTION_DEBUG|yes" "$@"
#     check_arg_value "h|host" "OPTION_HOST" "$@"
#     check_arg_shift && shift $CHECK_ARG_SHIFT && continue
#     echo_error "Unknown argument: $1" 1
# done
{
    ARG_NAME_SHORT="${1%|*}"
    ARG_NAME_LONG="${1#*|}"
    ARG_NAME_VAR="${2%|*}"
    ARG_NAME_VALUE="${2#*|}"
    shift 2
    #echo_debug_variable ARG_NAME_SHORT ARG_NAME_LONG ARG_NAME_VAR ARG_NAME_VALUE

    if test "$1" = "--$ARG_NAME_LONG" -o "$1" = "-$ARG_NAME_SHORT"
    then
        eval ${ARG_NAME_VAR}="$ARG_NAME_VALUE"
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    return 1
}

function check_arg_value
# $1 short|long
# $2 variable
# $3 arguments
# usage: check_arg_value "h|host" "OPTION_HOST" "$@"
# example:
# while test $# -gt 0
# do
#     check_arg_init
#     check_arg_switch "d|debug" "OPTION_DEBUG|yes" "$@"
#     check_arg_value "h|host" "OPTION_HOST" "$@"
#     check_arg_shift && shift $CHECK_ARG_SHIFT && continue
#     echo_error "Unknown argument: $1" 1
# done
{
    ARG_NAME_SHORT="${1%|*}"
    ARG_NAME_LONG="${1#*|}"
    ARG_NAME_VAR="$2"
    shift 2
    #echo_debug_variable ARG_NAME_SHORT ARG_NAME_LONG ARG_NAME_VAR

    if test "$1" = "--$ARG_NAME_LONG" -o "$1" = "-$ARG_NAME_SHORT"
    then
        test $# -eq 1 && echo_error "Missing value for argument \"$1\"" 99
        eval ${ARG_NAME_VAR}="$2"
        CHECK_ARG_SHIFT+=2
        return 0
    fi

    if test "${1%%=*}" = "--$ARG_NAME_LONG"
    then
        eval ${ARG_NAME_VAR}="${1#*=}"
        CHECK_ARG_SHIFT+=1
        return 0
    fi

    return 1
}

function prepare_file
{
    local FILE=""
    local EMPTY="no"
    local ROLL="no"
    local USER=""
    local GROUP=""
    while test $# -gt 0
    do
        check_arg_init
        check_arg_switch "e|empty" "EMPTY|yes" "$@"
        check_arg_switch "r|roll" "ROLL|yes" "$@"
        check_arg_shift && shift $CHECK_ARG_SHIFT && continue
        test -z "$FILE" && FILE="$1" && shift && continue
        echo_error_function "prepare_file" "Unknown argument: $1" 1
    done
    test -z "$FILE" && echo_error_function "prepare_file" "Filename is not specified" 1

    mkdir -p "`dirname $FILE`"

    if test_yes "$ROLL"
    then
        test -f "$FILE-9" && rm -f "$FILE-9"
        for N in 8 7 6 5 4 3 2 1
        do
            let N1=N+1
            test -f "$FILE-$N" && mv "$FILE-$N" "$FILE-$N1"
        done
        test -f "$FILE" && mv "$FILE" "$FILE-1"
    fi

    test_yes "$EMPTY" && rm -f "$FILE"

    touch "$FILE"
    test -f "$FILE" || echo_error_function "prepare_file" "Can't create the file: $FILE" 1
    chmod ug+w "$FILE" 2> /dev/null
    test -n "$PREPARE_FILE_USER" && chgrp "$PREPARE_FILE_USER" "$FILE" 2> /dev/null
    test -n "$PREPARE_FILE_GROUP" && chown "$PREPARE_FILE_GROUP" "$FILE" 2> /dev/null
}

function get_remote_file
# $1 ssh connect: user@host
# $2 remote file
{
    local REMOTE_SSH="$1"
    local REMOTE_FILE="$2"
    LOCAL_TEMP_FILE="/tmp/`basename "$REMOTE_FILE"`.$$"
    rm -f "$LOCAL_TEMP_FILE"
    scp -q "$REMOTE_SSH":"$REMOTE_FILE" "$LOCAL_TEMP_FILE" || return 1
    #echo "$LOCAL_TEMP_FILE"
}

function put_remote_file
# $1 ssh connect: user@host
# $2 remote file
{
    local REMOTE_SSH="$1"
    local REMOTE_FILE="$2"
    LOCAL_TEMP_FILE="/tmp/`basename "$REMOTE_FILE"`.$$"
    scp -q "$LOCAL_TEMP_FILE" "$REMOTE_SSH":"$REMOTE_FILE" || return 1
    rm -f "$LOCAL_TEMP_FILE"
}

function file_line_remove
# $1 filename
# $2 remove regexp
{
    local FILE="$1"
    local TEMP_FILE="/tmp/`basename "$FILE"`.tmp"
    local REGEXP="$2"
    if test -r "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE"
        if diff "$FILE" "$TEMP_FILE" > /dev/null 2> /dev/null
        then
            cat "$TEMP_FILE" 2> /dev/null | "$GREP" -v "$REGEXP" > "$FILE" 2> /dev/null
            /bin/rm -f "$TEMP_FILE"
        else
            /bin/rm -f "$TEMP_FILE"
            echo_error "$FILE line \"$REGEXP\" remove fail" 99
        fi
    fi
}

function file_line_add
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

    test -e "$FILE" || touch "$FILE"

    if test -z "$REGEXP_AFTER$REGEXP_REPLACE"
    then
        echo "$LINE" >> "$FILE"
    else
        cat "$FILE" > "$TEMP_FILE"
        if test -n "$REGEXP_REPLACE" && `cat "$TEMP_FILE" | "$AWK" 'BEGIN { f=1; } /'"$REGEXP_REPLACE"'/ { f=0; } END { exit f; }'`
        then
            cat "$TEMP_FILE" | "$AWK" -v line="$LINE" 'BEGIN { p=0; gsub(/\n/, "\\n", line); } p==0&&/'"$REGEXP_REPLACE"'/ { p=1; print line; next } { print; } END { if (p==0) print line; }' > "$FILE"
        elif test -n "$REGEXP_AFTER" && `cat "$TEMP_FILE" | "$AWK" 'BEGIN { f=1; } /'"$REGEXP_AFTER"'/ { f=0; } END { exit f; }'`
        then
            cat "$TEMP_FILE" | "$AWK" -v line="$LINE" 'BEGIN { p=0; gsub(/\n/, "\\n", line); } p==0&&/'"$REGEXP_AFTER"'/ { print $0; p=1; print line; next } { print; } END { if (p==0) print line; }' > "$FILE"
        else
            cat "$TEMP_FILE" | "$AWK" -v line="$LINE" 'BEGIN { gsub(/\n/, "\\n", line); } { print; } END { print line; }' > "$FILE"
        fi
        if test -s "$FILE"
        then
            /bin/rm -f "$TEMP_FILE"
        else
            cat "$TEMP_FILE" > "$FILE"
            /bin/rm -f "$TEMP_FILE"
            echo_error "$FILE add \"$LINE\" fail" 99
        fi
    fi
}

function file_line_set
# $1 filename
# $2 add this line (and check before if there is not present)
# $3 add after this regexp line (or if not found put at end of file)
# $4 replace this line (or if not found add after $3)
{
    local FILE="$1"
    local LINE="$2"
    local REGEXP_AFTER="$3"
    local REGEXP_REPLACE="$4"

    if ! "$GREP" --quiet --line-regexp --fixed-strings -- "$LINE" "$FILE"
    then
        file_line_add "$FILE" "$LINE" "$REGEXP_AFTER" "$REGEXP_REPLACE"
        return 1
    else
        return 0
    fi
}

function file_line_add1
{
    file_line_set "$1" "$2" "$3" "$4"
}

function lr_file_line_add
# $1 ssh connect: user@host
# $* as for file_line_add1 function
{
    local REMOTE_SSH="$1"
    shift

    local FILE="$1"
    local LINE="$2"
    local REGEXP="$3"
    
    if is_localhost "`echo "$REMOTE_SSH" | sed 's/^.*@//'`"
    then
        file_line_add1 "$FILE" "$LINE" "$REGEXP"
    else
        get_remote_file "$REMOTE_SSH" "$FILE"
        #ls -la "$LOCAL_TEMP_FILE"
        file_line_add "$FILE" "$LINE" "$REGEXP"
        #ls -la "$LOCAL_TEMP_FILE"
        put_remote_file "$REMOTE_SSH" "$FILE"
    fi
}

function lr_file_line_add1
# $1 ssh connect: user@host
# $* as for file_line_add1 function
{
    local REMOTE_SSH="$1"
    shift

    local FILE="$1"
    local LINE="$2"
    local REGEXP="$3"
    
    if is_localhost "`echo "$REMOTE_SSH" | sed 's/^.*@//'`"
    then
        file_line_add1 "$FILE" "$LINE" "$REGEXP"
    else
        get_remote_file "$REMOTE_SSH" "$FILE"
        #ls -la "$LOCAL_TEMP_FILE"
        file_line_add1 "$LOCAL_TEMP_FILE" "$LINE" "$REGEXP"
        #ls -la "$LOCAL_TEMP_FILE"
        put_remote_file "$REMOTE_SSH" "$FILE"
    fi
}

function file_config_set
# $1 filename
# $2 option
# $3 new value
{
    local CONFIG_FILE="$1"
    local CONFIG_TEMP_FILE="/tmp/`basename "$CONFIG_FILE"`.tmp"
    local OPTION="$2"
    local VALUE="$3"
    if test -e "$CONFIG_FILE"
    then
        cat "$CONFIG_FILE" > "$CONFIG_TEMP_FILE"
        cat "$CONFIG_TEMP_FILE" | "$AWK" 'BEGIN { found=0; } /^'$OPTION'=/ { print "'"$OPTION"'=\"'"$VALUE"'\""; found=1; next; } { print; } END { if (found == 0) print "'"$OPTION"'=\"'"$VALUE"'\""; }' > "$CONFIG_FILE"
        if test -s "$CONFIG_FILE"
        then
            /bin/rm -f "$CONFIG_TEMP_FILE"
        else
            cat "$CONFIG_TEMP_FILE" > "$CONFIG_FILE"
            /bin/rm -f "$CONFIG_TEMP_FILE"
            echo_error "file $CONFIG_FILE new configuration \"$OPTION=\"$VALUE\"\" change fail" 99
        fi
    else
        echo "$OPTION=\"$VALUE\"" > "$CONFIG_FILE"
    fi
}

function file_replace
# $1 filename
# $2 search
# $3 replace
{
    local FILE="$1"
    local TEMP_FILE="/tmp/`basename "$CONFIG_FILE"`.tmp"
    local SEARCH="$2"
    local REPLACE="$3"
    if test -e "$FILE"
    then
        cat "$FILE" > "$TEMP_FILE"
        cat "$TEMP_FILE" | sed --expression="s|$SEARCH|$REPLACE|g" > "$FILE"
        if test -s "$FILE"
        then
            /bin/rm -f "$TEMP_FILE"
        else
            cat "$TEMP_FILE" > "$FILE"
            /bin/rm -f "$TEMP_FILE"
            echo_error "file $FILE string $SEARCH replace fail" 99
        fi
    fi
}

function check_ssh
# $1 [user@]hostname
# $2 check via local username
{
    if test -z "$2"
    then
        ssh -q -o "BatchMode=yes" -o "ConnectTimeout=5" "$1" "exit" 2> /dev/null
    else
        su - "$2" "ssh -q -o \"BatchMode=yes\" -o \"ConnectTimeout=5\" \"$1\" \"exit\" 2> /dev/null"
    fi
    return $?
}

function check_internet
{
    curl --output /dev/null --silent "www.centos.org"
    return $?
}

function get_ip_arp
{
    local GET_IP_ARP="`arp "$1" 2> /dev/null | "$AWK" 'BEGIN { FS="[()]"; } { print $2; }'`"
    if test "$UNIX_TYPE" = "Linux" -a -z "$GET_IP_ARP"
    then
        GET_IP_ARP="`arp -n "$1" | "$AWK" '/ether/ { print $1; }'`"
    fi
    echo "$GET_IP_ARP"
}

function get_ip_ping
{
    test "$UNIX_TYPE" = "SunOS" && ping -s "$1" 1 1 | grep "bytes from" | "$AWK" 'BEGIN { FS="[()]"; } { print $2; }'
    test "$UNIX_TYPE" = "Linux" && ping -q -c 1 -t 1 "$1" | grep PING | "$AWK" 'BEGIN { FS="[()]"; } { print $2; }'
}

function get_ip
{
    local HOST="$1"
    test -z "$HOST" && HOST="`hostname`"

    local GET_IP="`get_ip_arp "$HOST"`"
    test -z "$GET_IP" && GET_IP="`get_ip_ping "$HOST"`"
    echo "$GET_IP"
}

function is_localhost
{
    UNAME_N="`uname -n`"
    UNAME_IP="`get_ip "$UNAME_N"`"
    REMOTE_IP="`get_ip "$1"`"

    #echo_debug_variable UNAME_N UNAME_IP REMOTE_IP

    test -z "$1" -o "$1" = "localhost" -o "$1" = "127.0.0.1" -o "$1" = "$UNAME_N" -o "$REMOTE_IP" = "$UNAME_IP" && return 0

    return 1
}

function get_id
{
    id | "$AWK" 'BEGIN { FS="[()]"; } { print $2; }'
}

function ssh_scanid
# $1 @user scan to user
# $2 scan hosts
# ssh_scanid @root host `get_ip host`
{
    local SCAN_HOSTS=""
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

    #echo "Scan host ids $SCAN_HOSTS to $SCAN_USER_HOME_SSH_HOSTS"
    ssh-keyscan $SCAN_HOSTS >> "$SCAN_USER_HOME_SSH_HOSTS" 2> /dev/null
    cp "$SCAN_USER_HOME_SSH_HOSTS" "${SCAN_USER_HOME_SSH_HOSTS}_orig"
    cat "${SCAN_USER_HOME_SSH_HOSTS}_orig" | sort -u > "$SCAN_USER_HOME_SSH_HOSTS"
    rm -f "${SCAN_USER_HOME_SSH_HOSTS}_orig"
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
        #echo "Use $USEID_FILE and scan via $DEST_USER @ $DEST_HOST to user $DEST_LOCAL_USER"
        ssh -i $USEID_FILE $DEST_USER@$DEST_HOST "
            umask 077
            DEST_HOME=~$DEST_LOCAL_USER
            DEST_HOME_SSH=~$DEST_LOCAL_USER/.ssh
            DEST_HOME_SSH_HOSTS=~$DEST_LOCAL_USER/.ssh/known_hosts
            test -d \$DEST_HOME_SSH || mkdir \$DEST_HOME_SSH
            chown --reference=\$DEST_HOME \$DEST_HOME_SSH
            touch \$DEST_HOME_SSH_HOSTS
            chown --reference=\$DEST_HOME \$DEST_HOME_SSH_HOSTS
            ssh-keyscan `hostname` `hostname --fqdn` `hostname --short` `get_ip` >> \$DEST_HOME_SSH_HOSTS 2> /dev/null
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
        #echo "Use $USEID_FILE and copy ${COPYID_FILE}.pub via $DEST_USER @ $DEST_HOST to user $DEST_LOCAL_USER"
        cat "${COPYID_FILE}.pub" | ssh -i $USEID_FILE $DEST_USER@$DEST_HOST "
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

        #echo "Use $USEID_FILE and copy id via $DEST_USER @ $DEST_HOST to user $DEST_LOCAL_USER"

        test -z "$COPYID_USER" && COPYID_HOME=~ || COPYID_HOME="`eval echo "~$COPYID_USER"`"
        COPYID_HOME_SSH="$COPYID_HOME/.ssh"
        COPYID_HOME_SSH_KEYS="$COPYID_HOME_SSH/authorized_keys"

        test -z "$DEST_LOCAL_USER" && DEST_HOME="~" || DEST_HOME="~$DEST_LOCAL_USER"
        DEST_HOME_SSH="$DEST_HOME/.ssh"

        test -d $COPYID_HOME_SSH || mkdir $COPYID_HOME_SSH
        chown --reference=$COPYID_HOME $COPYID_HOME_SSH
        touch $COPYID_HOME_SSH_KEYS
        chown --reference=$COPYID_HOME $COPYID_HOME_SSH_KEYS

        for TEST_FILE in "$DEST_HOME_SSH/id_rsa.pub" "$DEST_HOME_SSH/id_dsa.pub"
        do
            ssh -i $USEID_FILE $DEST_USER@$DEST_HOST "test -f $TEST_FILE"
            test $? -eq 0 && DESTID_FILE="$TEST_FILE" && break
        done
        test -z "$DESTID_FILE" && return 2

        scp -i $USEID_FILE $DEST_USER@$DEST_HOST:$DESTID_FILE $COPYID_HOME_SSH/id_import.pub > /dev/null 2>&1
        if test $? -eq 0
        then
            cat $COPYID_HOME_SSH/id_import.pub >> $COPYID_HOME_SSH_KEYS
            rm -f $COPYID_HOME_SSH/id_import.pub
            cp $COPYID_HOME_SSH_KEYS ${COPYID_HOME_SSH_KEYS}_orig
            cat ${COPYID_HOME_SSH_KEYS}_orig | sort -u > $COPYID_HOME_SSH_KEYS
            rm -f ${COPYID_HOME_SSH_KEYS}_orig
        else
            return 1
        fi
    done
}

function call_command
{
    local HOST=""
    local TOPT=""
    local USER="$CALL_COMMAND_DEFAULT_USER"
    local USER_SET="no"
    local DEBUG="yes"
    while test $# -gt 0
    do
        test "$1" = "--nodebug" && DEBUG="no" && shift && continue
        test "$1" = "--term" -o "$1" = "-t" && TOPT="-t" && shift && continue
        test "$1" = "--host" -o "$1" = "-h" && shift && HOST="$1" && shift && continue
        test "${1%%=*}" = "--host" && HOST="${1#*=}" && shift && continue
        test "$1" = "--user" -o "$1" = "-u" && shift && USER="$1" && USER_SET="yes" && shift && continue
        test "${1%%=*}" = "--user" && USER="${1#*=}" && shift && continue
        break
    done

    if is_localhost "$HOST"
    then
        test_yes "$DEBUG" && echo_debug_right "$@"
        if test_no "$USER_SET" -o "`get_id`" = "$USER"
        then
            bash -c "$@"
            TOOL_EXEC_EXIT_CODE="$?"
        else
            su - "$USER" "$@"
            TOOL_EXEC_EXIT_CODE="$?"
        fi
    else
        echo_debug_right "ssh $TOPT \"$USER@$HOST\" \"$@\""
        ssh $TOPT "$USER@$HOST" "$@"
        TOOL_EXEC_EXIT_CODE="$?"
    fi

    return $TOOL_EXEC_EXIT_CODE
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
    if test_yes "$TOPMOST" -a "$CHECK_PID" != "$$"
    then
        test_yes "$ECHO_KILL" && echo_line "Killing process with $CHECK_PID PID" && ps -ef | awk --assign p="$CHECK_PID" '$2==p { print "Killed: "$0; }' | echo_output
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
{
    kill_tree `ps -ef | grep -v $$ | awk --assign p="$1" --assign s="$$" '$3==s { next; } $0~p { print $2; }'`
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
    echo $FILE_FD
}

function test_ne0
{
    test $? -ne 0
}

function fill_command_options
{
    export COMMAND="$1"
    export OPTIONS="$2 $3 $4 $5 $6 $7 $8 $9"
    export OPTIONS2="$3 $4 $5 $6 $7 $8 $9"
    export OPTION="$2"
    export OPTION2="$3"
    export OPTION3="$4"
    unset OPTIONS_A
    declare -a OPTIONS_A=("$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9")
}

function test_boolean
# $1 integer
{
    [[ "$1" =~ ^(y|Y|yes|Yes|YES|true|True|TRUE)$ ]]
}

function test_yes
# $1 integer
{
    [[ "$1" =~ ^(y|Y|yes|Yes|YES)$ ]]
}

function test_no
# $1 integer
{
    [[ "$1" =~ ^(n|N|no|No|NO)$ ]]
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

function test_str
# $1 string to test
# $2 regexp
{
    local IGNORE_CASE=""
    test "$1" = "-i" && IGNORE_CASE="--ignore-case" && shift
    test "$#" != "2" && echo_error_function "test_str" "Wrong parameters count"

    /bin/echo "$1" | grep --quiet --extended-regexp $IGNORE_CASE "$2"
    return $?
}

function test_file
# $1 string to test
# $2 regexp
{
    test "$#" != "2" && echo_error_function "test_file" "Wrong parameters count"

    test -f "$2" || return 1

    grep --quiet --extended-regexp "$1" "$2"
    return $?
}

function test_cmd
# [$1] string to test
# $2 regexp
{
    local CMD="$COMMAND"

    if test "$#" = "2"
    then
        CMD="$1"
        shift
    fi

    echo "$CMD" | egrep --quiet "$1"
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
        /bin/echo -en "\033[6n"
        read -s -d "R" CURSOR_POSITION
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

function pipe_from
# command | pipe_from "from this line"
{
    "$AWK" --assign=from="$1" '
        BEGIN { show=0; }
        show==1 { print; next; }
        $0~from { show=1; print; }
    '
}

LOG_FILE=""
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
        test "${1:0:1}" = "/" && LOG_FILE="$1" || LOG_TITLE="$1"
        shift
    done
    test -z "$LOG_FILE" && LOG_FILE="`echo "$0" | sed --regexp-extended --expression='s:(|\.|\.sh)$:.log:'`"

    prepare_file "$LOG_FILE"
    /bin/echo "$LOG_SECTION" >> "$LOG_FILE"
    /bin/echo "`date +"$LOG_DATE"` $LOG_TITLE" >> "$LOG_FILE"
}

function log_file_done
{
    log_done "$@"
}

function log_done
{
    local LOG_TITLE="$0 - Log done"
    test $# -eq 2 && LOG_TITLE="$1" && shift
    test -z "$LOG_FILE" && echo_error_function "log_done" "Log file is not specified"

    local LOG_DURATION
    let LOG_DURATION=`date -u +%s`-$LOG_START

    prepare_file "$LOG_FILE"
    /bin/echo "`date +"$LOG_DATE"` $LOG_TITLE, script runtime $LOG_DURATION seconds" >> "$LOG_FILE"
    /bin/echo "$LOG_SECTION" >> "$LOG_FILE"
}

function echo_log
# echoes arguments only to log file
{
    test -z "$LOG_FILE" && return

    local LOG_DATE_STRING=""
    test_str "$1" "(-d|--date)" && LOG_DATE_STRING="`date +"$LOG_DATE"` " && shift

    prepare_file "$LOG_FILE"
    #echo "${LOG_SPACE}$@" | sed --expression='s/\\n/\n                    /g' --expression='s/^/                    /g' >> "$LOG_FILE"
    /bin/echo "${LOG_SPACE}${LOG_DATE_STRING}$@" | pipe_remove_color >> "$LOG_FILE"
}

function log_output
{
    pipe_log
}

function pipe_log
# pipe with command echo_log
{
    BACKUP_IFS="$IFS"
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
    BACKUP_IFS="$IFS"
    IFS=''
    while read LINE
    do
        echo_line "$LINE"
    done
    IFS="$BACKUP_IFS"
}

function show_output
{
    pipe_echo_prefix "$@"
}

function pipe_echo_prefix
# pipe with pipe_echo and nice output
# command | show_output
# -c <command> | --command=<command>
# -p <prefix> | --prefix=<prefix>
{
    local PREFIX="$SHOW_OUTPUT_PREFIX"
    local HIDELINES="$SHOW_OUTPUT_HIDELINES"
    local COMMAND="$SHOW_OUTPUT_COMMAND"

    while test $# -gt 0
    do
        check_arg_init
        check_arg_value "p|prefix" "PREFIX" "$@"
        check_arg_value "c|command" "COMMAND" "$@"
        check_arg_shift && shift $CHECK_ARG_SHIFT && continue
        test -z "$HIDELINES" && HIDELINES="$1" && shift && continue
        echo_error_function "show_output" "Unknown argument: $1" 1
    done

    #while read LINE
    #do
    #    echo "$PREFIX$LINE"
    #done

    "$AWK" --assign=prefix="$PREFIX" --assign=hideline="$HIDELINES" --assign=command="$COMMAND" '
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

        hideline!="" && current~hideline { next; }
        current==line { count++; next; }
        count==0 { line=current; count++; next; }
        count==1 { print prefix line; line=current; count=1; next; }
        count>1 { print prefix line " ("count"x)"; line=current; count=1; next; }
        END { if (count>1) p=" ("count"x)"; else p=""; print prefix line p; }' | pipe_echo
}

# echo $TERM
# ok xterm/rxvt/konsole/linux
# no dumb/sun

function echo_line
# usage as standard echo
# echoes arguments to standard output and log to the file
{
    /bin/echo "$@"
    echo_log "$@"
}

function echo_info
{
    if test_yes "$OPTION_COLOR"
    then
        /bin/echo -e "${COLOR_INFO}${ECHO_PREFIX}${ECHO_UNAME}$@${COLOR_RESET}"
    else
        /bin/echo "${ECHO_PREFIX}${ECHO_UNAME}$@"
    fi

    echo_log "${ECHO_PREFIX}${ECHO_UNAME}$@"
}

function echo_step
{
    if test_yes "$OPTION_COLOR"
    then
        /bin/echo -e "${COLOR_STEP}${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_STEP}$@${COLOR_RESET}"
    else
        /bin/echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_STEP}$@"
    fi

    echo_log "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_STEP}$@"
}

function echo_substep
{
    if test_yes "$OPTION_COLOR"
    then
        /bin/echo -e "${COLOR_SUBSTEP}${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_SUBSTEP}$@${COLOR_RESET}"
    else
        /bin/echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_SUBSTEP}$@"
    fi

    echo_log "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_SUBSTEP}$@"
}

function set_debug
{
    local OPTION="${1:-yes}"
    echo "$OPTION_DEBUG" | grep --quiet --word-regexp "$OPTION" || OPTION_DEBUG="$OPTION,$OPTION_DEBUG"
}

function unset_debug
{
    local OPTION="${1:-yes}"
    OPTION_DEBUG="${OPTION/$OPTION?(,)/}"
}

function check_debug
{
    local OPTION="${1:-yes}"
    echo "$OPTION_DEBUG" | grep --quiet --word-regexp "$OPTION"
}

function echo_debug
{
    if check_debug
    then
        if test_yes "$OPTION_COLOR"
        then
            echo -e "${COLOR_DEBUG}${ECHO_PREFIX}${ECHO_UNAME}$@${COLOR_RESET}" >&$REDIRECT_DEBUG
        else
            echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_DEBUG}$@" >&$REDIRECT_DEBUG
        fi
    fi

    echo_log --date "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_DEBUG}$@"
}

function echo_debug_right
{
    if check_debug right
    then
        if test_yes "$OPTION_COLOR"
        then
            local DEBUG_MESSAGE="${ECHO_PREFIX}${ECHO_UNAME}$@"
        else
            local DEBUG_MESSAGE="${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_DEBUG}$@"
        fi
        local SHIFT_MESSAGE="`tput cols`"
        let SHIFT_MESSAGE="$SHIFT_MESSAGE-${#DEBUG_MESSAGE}"

        cursor_get_position
        #tput sc
        /bin/echo -e "\r\c" >&$REDIRECT_DEBUG
        test $SHIFT_MESSAGE -ge 25 && tput cuu1 >&$REDIRECT_DEBUG && tput cuf $SHIFT_MESSAGE >&$REDIRECT_DEBUG
        /bin/echo -e "${COLOR_DEBUG}$DEBUG_MESSAGE${COLOR_RESET}" >&$REDIRECT_DEBUG
        #tput rc
        let CURSOR_COLUMN--
        test $CURSOR_COLUMN -ge 1 && tput cuf $CURSOR_COLUMN >&$REDIRECT_DEBUG
        #test $SHIFT_MESSAGE -ge 15 || cursor_move_down
    fi

    echo_log --date "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_DEBUG}$@"
}

function echo_debug_variable
{
    local VAR_LIST=""
    while test $# -gt 0
    do
        local VAR_NAME="$1"
        shift
        test -n "$VAR_LIST" && VAR_LIST="$VAR_LIST "
        VAR_LIST="${VAR_LIST}${VAR_NAME}=\"${!VAR_NAME}\""
    done
    echo_debug "$VAR_LIST"
}

function echo_debug_var
{
    echo_debug_variable "$@"
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
            echo -e "${COLOR_DEBUG}${ECHO_PREFIX}${ECHO_UNAME}${FUNCTION_INFO}${COLOR_RESET}" >&$REDIRECT_DEBUG
        else
            echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_DEBUG}${FUNCTION_INFO}" >&$REDIRECT_DEBUG
        fi
    fi

    echo_log --date "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_DEBUG}${FUNCTION_INFO}"
}

function echo_debug_funct
{
    echo_debug_function "$@"
}

function echo_error
{
    local EXIT_CODE=""
    local ECHO_ERROR="$@"
    test_integer "${@:(-1)}" && local EXIT_CODE=$2 && ECHO_ERROR="${@:1:${#@}-1}"

    if test_yes "$OPTION_COLOR"
    then
        echo -e "$COLOR_ERROR${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_ERROR}${ECHO_ERROR}!$COLOR_RESET" >&$REDIRECT_ERROR
    else
        echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_ERROR}${ECHO_ERROR}!" >&$REDIRECT_ERROR
    fi

    echo_log "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_ERROR}${ECHO_ERROR}!"

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
    ECHO_FUNCTION="${ECHO_FUNCTION/ */}"
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

    echo_error "[$ECHO_FUNCTION] $ECHO_ERROR" #$EXIT_CODE
}

function echo_warning
{
    local EXIT_CODE=""
    local ECHO_WARNING="$@"
    test_integer "${@:(-1)}" && local EXIT_CODE=$2 && ECHO_WARNING="${@:1:${#@}-1}"

    if test_yes "$OPTION_COLOR"
    then
        echo -e "$COLOR_WARNING${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_WARNING}${ECHO_WARNING}.$COLOR_RESET" >&$REDIRECT_WARNING
    else
        echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_WARNING}${ECHO_WARNING}." >&$REDIRECT_WARNING
    fi

    echo_log "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_PREFIX_WARNING}${ECHO_WARNING}."

    test -n "$EXIT_CODE" && exit $EXIT_CODE
}

### tools exports

export REDIRECT_DEBUG=2
export REDIRECT_ERROR=1
export REDIRECT_WARNING=1

export OPTION_DEBUG
export OPTION_PREFIX="no"
export OPTION_COLOR
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

export COLOR_INFO
export COLOR_STEP
export COLOR_SUBSTEP
export COLOR_DEBUG
export COLOR_ERROR
export COLOR_WARNING

export -f query
export -f query_yn
export -f query_ny

declare -a PARSE_ARGS=()
export PARSE_ARGS=()
export -f str_parse_args
export -f str_get_arg
export -f str_get_arg_from

declare -i CHECK_ARG_SHIFT=0
export CHECK_ARG_SHIFT
export -f check_arg_switch
export -f check_arg_value

export PREPARE_FILE_USER=""
export PREPARE_FILE_GROUP=""
export -f prepare_file

export -f get_remote_file
export -f put_remote_file

export -f file_line_remove
export -f file_line_add
export -f file_line_add1
export -f lr_file_line_add
export -f lr_file_line_add1

export -f file_config_set
export -f file_replace

export -f check_ssh
export -f check_internet

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

export -f kill_tree_childs
export -f kill_tree

export -f fd_check
export -f fd_find_free

export -f test_ne0
export -f fill_command_options
export -f test_boolean
export -f test_yes
export -f test_no
export -f test_integer
export -f test_str
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

export SHOW_OUTPUT_PREFIX="  >  "
export SHOW_OUTPUT_HIDELINES="" # regexp to hide lines
export SHOW_OUTPUT_COMMAND=""
export SHOW_OUTPUT_DEDUPLICATE="yes"

export -f log_init;         export -f log_file_init
export -f log_done;         export -f log_file_done
export -f echo_log

export -f pipe_log;         export -f log_output
export -f pipe_echo;        export -f echo_output
export -f pipe_echo_prefix; export -f show_output

export -f echo_line
export -f echo_info
export -f echo_step
export -f echo_substep
export -f echo_debug
export -f echo_debug_right
export -f echo_debug_variable
export -f echo_debug_var
export -f echo_debug_function
export -f echo_debug_funct
export -f echo_error
export -f echo_error_ne0
export -f echo_error_function
export -f echo_error_exit
export -f echo_warning

### tools init

while test $# -gt 0
do
    check_arg_init
    check_arg_switch "d|debug" "OPTION_DEBUG|yes" "$@" && set_debug right
    check_arg_switch "|debug-right" "OPTION_DEBUG|right,$OPTION_DEBUG" "$@"
    check_arg_switch "|debug-function" "OPTION_DEBUG|function,$OPTION_DEBUG" "$@"
    check_arg_switch "p|prefix" "OPTION_PREFIX|yes" "$@"
    check_arg_value "c|color" "OPTION_COLOR" "$@"
    check_arg_value "u|uname" "OPTION_UNAME" "$@"
    check_arg_shift && shift $CHECK_ARG_SHIFT && continue
    if test -z "$TOOLS"
    then
        TOOLS="$1"
        TOOLSNAME="`basename $TOOLS`"
        TOOLSDIR="`dirname $TOOLS`"
        shift && continue
    fi
    echo_error "Unknown argument: $1" 1
done

#if test -z "$ECHO_PREFIX_DEBUG"
#then
#    ECHO_PREFIX_DEBUG="@@@ "
#fi

#if test -z "$ECHO_PREFIX_ERROR"
#then
#    ECHO_PREFIX_ERROR="error: "
#fi

#if test -z "$OPTION_PREFIX"
#then
#    OPTION_PREFIX="yes"
#fi

test_yes "$OPTION_PREFIX" && ECHO_PREFIX="### "

test_yes "$OPTION_UNAME" && ECHO_UNAME="`uname -n`: " || ECHO_UNAME=""

if ! test_yes "$OPTION_COLOR" -a ! test_no "$OPTION_COLOR"
then
    #echo "Color is \"$OPTION_COLOR\"; setting..."
    if test "`echo "$TERM" | cut -c 1-5`" = "xterm" -o "$TERM" = "rxvt" -o "$TERM" = "konsole" -o "$TERM" = "linux"
    then
        OPTION_COLOR="yes"
    else
        OPTION_COLOR="no"
    fi
    #echo "Color is $OPTION_COLOR"
fi

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
    COLOR_LIGHT_GRAY="\033[37m"

    COLOR_DARK_GRAY="\033[90m"
    COLOR_LIGHT_RED="\033[91m"
    COLOR_LIGHT_GREEN="\033[92m"
    COLOR_LIGHT_YELLOW="\033[93m"
    COLOR_LIGHT_BLUE="\033[94m"
    COLOR_LIGHT_MAGENTA="\033[95m"
    COLOR_LIGHT_CYAN="\033[96m"
    COLOR_WHITE="\033[97m"

    COLOR_ORANGE="\033[38;5;208m"

    COLOR_X="\033[38;5;236m"
    COLOR_INFO="$COLOR_LIGHT_YELLOW"
    COLOR_STEP="$COLOR_WHITE"
    COLOR_SUBSTEP="$COLOR_WHITE"
    COLOR_DEBUG="$COLOR_X"
    COLOR_ERROR="$COLOR_LIGHT_RED"
    COLOR_WARNING="$COLOR_CYAN"

    # definitions for readline / awk / prompt
    COLOR_RESET_E="\001${COLOR_RESET}\002"

    COLOR_BLACK_E="\001${COLOR_BLACK}\002"
    COLOR_RED_E="\001${COLOR_RED}\002"
    COLOR_GREEN_E="\001${COLOR_GREEN}\002"
    COLOR_YELLOW_E="\001${COLOR_YELLOW}\002"
    COLOR_BLUE_E="\001${COLOR_BLUE}\002"
    COLOR_MAGENTA_E="\001${COLOR_MAGENTA}\002"
    COLOR_CYAN_E="\001${COLOR_CYAN}\002"
    COLOR_LIGHT_GRAY="\001${COLOR_LIGHT_GRAY}\002"

    COLOR_DARK_GRAY_E="\001${COLOR_DARK_GRAY}\002"
    COLOR_LIGHT_RED_E="\001${COLOR_LIGHT_RED}\002"
    COLOR_LIGHT_GREEN_E="\001${COLOR_LIGHT_GREEN}\002"
    COLOR_LIGHT_YELLOW_E="\001${COLOR_LIGHT_YELLOW}\002"
    COLOR_LIGHT_BLUE_E="\001${COLOR_LIGHT_BLUE}\002"
    COLOR_LIGHT_MAGENTA_E="\001${COLOR_LIGHT_MAGENTA}\002"
    COLOR_LIGHT_CYAN_E="\001${COLOR_LIGHT_CYAN}\002"
    COLOR_WHITE_E="\001${COLOR_WHITE}\002"

    COLOR_ORANGE_E="\001${COLOR_ORANGE}\002"

    COLOR_X_E="\001${COLOR_X}\002"
    COLOR_DEBUG_E="$COLOR_X_E"
else
    COLOR_RESET=""
    COLOR_DEBUG=""
fi
