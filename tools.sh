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

# echo $TERM
# ok xterm/rxvt/konsole/linux
# no dumb/sun

if test "`uname`" = "SunOS"
then
    AWK="/usr/bin/nawk"
fi
if test "`uname`" = "Linux"
then
    AWK="/bin/awk"
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

if test -z "$OPTION_PREFIX"
then
    OPTION_PREFIX="yes"
fi

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
