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

if test "`uname`" = "SunOS"
then
    AWK="/usr/bin/nawk"
fi
if test "`uname`" = "Linux"
then
    AWK="/bin/awk"
fi

echo_step()
{
    # ok xterm/rxvt
    # no dumb/sun
    
    if test "$OPTION_COLOR" = "yes"
    then
        echo -e "\E[1m${OPTION_PREFIX}${ECHO_UNAME}$*\033[0m"
    else
        echo "${OPTION_PREFIX}${ECHO_UNAME}$*"
    fi
}

echo_info()
{
    if test "$OPTION_COLOR" = "yes"
    then
        echo -e "\E[1m\E[33m${OPTION_PREFIX}${ECHO_UNAME}$*\033[0m"
    else
        echo "${OPTION_PREFIX}${ECHO_UNAME}error: $*"
    fi
}


echo_error()
{
    if test "$OPTION_COLOR" = "yes"
    then
        echo -e "\E[1m\E[31m${OPTION_PREFIX}${ECHO_UNAME}$*\033[0m"
    else
        echo "${OPTION_PREFIX}${ECHO_UNAME}error: $*"
    fi
}


while test $# -gt 0
do
    case "$1" in
      "-prefix")
        shift
        OPTION_PREFIX="$1"
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

if test -z "$OPTION_PREFIX"
then
    OPTION_PREFIX="### "
fi

if test "$OPTION_COLOR" != "yes" -a "$OPTION_COLOR" != "no"
then
    #echo "Color is \"$OPTION_COLOR\"; setting..."
    if test "`echo "$TERM" | cut -c 1-5`" = "xterm" -o "$TERM" = "rxvt" -o "$TERM" = "konsole"
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
