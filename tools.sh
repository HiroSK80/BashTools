#!/bin/bash

# execute as: ". <thisname> [options] <thisname> [options]"

# options:
# -prefix <prefix_string>
# -color yes|no
# -uname yes|no

query()
{
    QUESTION="$1"
    ERROR="$2"
    REGEXP="$3"
    DEFAULT="$4"

    if test -z "$DEFAULT"
    then
        QUERY="$QUESTION"
    else
        QUERY="$QUESTION (default: $DEFAULT)"
    fi

    if test "`uname`" = "SunOS"
    then
        if test -z "$REGEXP"
        then
            REGEXP=".*"
        fi
        if test -z "$DEFAULT"
        then
            REPLY=`ckstr -Q -r "$REGEXP" -p "$QUERY" -e "$ERROR"`
        else
            REPLY=`ckstr -Q -r "$REGEXP" -p "$QUERY" -e "$ERROR" -d "$DEFAULT"`
        fi
    fi

    if test "`uname`" = "Linux"
    then
        OK="no"
        until test "$OK" = "ok"
        do
            echo
            read -p "$QUERY [?] "
            if test -z "$REPLY"
            then
                REPLY="$DEFAULT"
            fi

            OK=`echo "$REPLY" | awk '/'$REGEXP'/ { print "ok"; exit } { print "no" }'`
            if test "$OK" = "no"
            then
                echo "        ERROR: $ERROR"
            fi
        done
    fi

    #echo $REPLY
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
# $3 add after this regexp line
{
    local FILE="$1"
    local TEMP_FILE="/tmp/`basename "$FILE"`.tmp"
    local LINE="$2"
    local REGEXP="$3"
    if test -z "$REGEXP"
    then
        echo "$LINE" >> "$FILE"
    else
        cat "$FILE" > "$TEMP_FILE"
        cat "$TEMP_FILE" | "$AWK" '/'"$REGEXP"'/ { print $0; print "'"$LINE"'"; next } { print; }' > "$FILE"
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

function file_line_add1
# $1 filename
# $2 add this line
# $3 add after this regexp line
{
    local FILE="$1"
    local LINE="$2"
    local REGEXP="$3"

    if ! "$GREP" -q -F "$LINE" "$FILE"
    then
        file_line_add "$FILE" "$LINE" "$REGEXP"
    fi
}

function set_config_option
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
        cat "$CONFIG_TEMP_FILE" | "$AWK" '/^'$OPTION'=/ { print "'"$OPTION"'=\"'"$VALUE"'\""; next } { print }' > "$CONFIG_FILE"
        if test -s "$CONFIG_FILE"
        then
            /bin/rm -f "$CONFIG_TEMP_FILE"
        else
            cat "$CONFIG_TEMP_FILE" > "$CONFIG_FILE"
            /bin/rm -f "$CONFIG_TEMP_FILE"
            echo_error "file $CONFIG_FILE new configuration \"$OPTION=\"$VALUE\"\" change fail" 99
        fi
    fi
}

function get_ip_arp
{
    local GET_IP_ARP="`arp "$1" 2> /dev/null | $AWK 'BEGIN { FS="[()]"; } { print $2; }'`"
    if test "`uname`" = "Linux" -a -z "$GET_IP_ARP"
    then
        GET_IP_ARP="`arp -n "$1" | awk '/ether/ { print $1; }'`"
    fi
    echo "$GET_IP_ARP"
}

function get_ip_ping
{
    if test "`uname`" = "SunOS"
    then
        ping -s "$1" 1 1 | grep "bytes from" | $AWK 'BEGIN { FS="[()]"; } { print $2; }'
    fi
    if test "`uname`" = "Linux"
    then
        ping -q -c 1 -t 1 "$1" | grep PING | $AWK 'BEGIN { FS="[()]"; } { print $2; }'
    fi
}

function get_ip
{
    local GET_IP="`get_ip_arp $1`"
    test -z "$GET_IP" && GET_IP="`get_ip_ping $1`"
    echo "$GET_IP"
}

function is_localhost
{
    UNAME_N="`uname -n`"
    UNAME_IP="`get_ip $UNAME_N`"
    REMOTE_IP="`get_ip $1`"

    if test -z "$1" -o "$1" = "localhost" -o "$1" = "127.0.0.1" -o "$1" = "$UNAME_N" -o "$REMOTE_IP" = "$UNAME_IP"
    then
        return 0
    fi

    return 1
}

function get_id
{
    id | $AWK 'BEGIN { FS="[()]"; } { print $2; }'
}

# echo $TERM
# ok xterm/rxvt/konsole/linux
# no dumb/sun

if test "`uname`" = "SunOS"
then
    AWK="/usr/bin/nawk"
    GREP="/usr/xpg4/bin/grep"
fi
if test "`uname`" = "Linux"
then
    AWK="/bin/awk"
    GREP="/bin/grep"
fi

if test "`echo "$TERM" | cut -c 1-5`" = "xterm" -o "$TERM" = "rxvt" -o "$TERM" = "konsole" -o "$TERM" = "linux"
then
    COLOR_RESET="\033[0m"
    COLOR_RED="\E[1m\E[31m"
    COLOR_GREEN="\E[1m\E[32m"
    COLOR_WHITE="\E[1m"
    COLOR_YELLOW="\E[1m\E[33m"
    COLOR_CYAN="\E[1m\E[36m"
else
    COLOR_RESET=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_WHITE=""
    COLOR_YELLOW=""
    COLOR_CYAN=""
fi

echo_step()
{
    if test "$OPTION_COLOR" = "yes"
    then
        echo -e "${COLOR_WHITE}${ECHO_PREFIX}${ECHO_UNAME}$*${COLOR_RESET}"
    else
        echo "${ECHO_PREFIX}${ECHO_UNAME}$*"
    fi
}

echo_info()
{
    if test "$OPTION_COLOR" = "yes"
    then
        echo -e "${COLOR_YELLOW}${ECHO_PREFIX}${ECHO_UNAME}$*${COLOR_RESET}"
    else
        echo "${ECHO_PREFIX}${ECHO_UNAME}$*"
    fi
}

echo_debug()
{
    if test "$OPTION_DEBUG" = "yes"
    then
        if test "$OPTION_COLOR" = "yes"
        then
            echo -e "${COLOR_CYAN}${ECHO_PREFIX}${ECHO_UNAME}$*${COLOR_RESET}"
        else
            echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_DEBUG_PREFIX}$*"
        fi
    fi
}

function echo_debug_var
{
    local VAR_NAME="$1"
    echo_debug "$VAR_NAME=${!VAR_NAME}"
}

echo_error()
{
    if test "$OPTION_COLOR" = "yes"
    then
        echo -e "$COLOR_RED${ECHO_PREFIX}${ECHO_UNAME}$*$COLOR_RESET"
    else
        echo "${ECHO_PREFIX}${ECHO_UNAME}${ECHO_ERROR_PREFIX}$*"
    fi
}


while test $# -gt 0
do
    case "$1" in
      "-debug")
        OPTION_DEBUG="yes"
        ;;
      "-prefix")
        shift
        OPTION_PREFIX="yes"
        ;;
      "-color")
        shift
        OPTION_COLOR="$1"
        ;;
      "-uname")
        shift
        OPTION_UNAME="$1"
        ;;
      *)
        if test -z "$TOOLS"
        then
            TOOLS="$1"
            TOOLSNAME="`basename $TOOLS`"
            TOOLSDIR="`dirname $TOOLS`"
        else
            echo_error "Unknown parameter: $1"
        fi
        ;;
    esac

    shift
done

if test -z "$ECHO_DEBUG_PREFIX"
then
    ECHO_DEBUG_PREFIX="@@@ "
fi

if test -z "$ECHO_ERROR_PREFIX"
then
    ECHO_ERROR_PREFIX="error: "
fi

#if test -z "$OPTION_PREFIX"
#then
#    OPTION_PREFIX="yes"
#fi

if test "$OPTION_PREFIX" = "yes"
then
    ECHO_PREFIX="### "
fi

if test "$OPTION_COLOR" != "yes" -a "$OPTION_COLOR" != "no"
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

if test "$OPTION_UNAME" = "yes"
then
    ECHO_UNAME="`uname -n`: "
else
    ECHO_UNAME=""
fi
