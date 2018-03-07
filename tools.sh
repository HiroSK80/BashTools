#!/bin/bash

# execute as: ". <thisname> [options] <thisname> [options]"

# options:
# -color yes|no
# -uname yes|no

echo_step()
{
    # ok xterm/rxvt
    # no dumb/sun
    
    if test "$COLOR" = "yes"
    then
        echo -e "\E[1m### ${ECHO_UNAME}$*\033[0m"
    else
        echo "### ${ECHO_UNAME}$*"
    fi
}

echo_info()
{
    if test "$COLOR" = "yes"
    then
        echo -e "\E[1m\E[33m### ${ECHO_UNAME}$*\033[0m"
    else
        echo "### ${ECHO_UNAME}error: $*"
    fi
}


echo_error()
{
    if test "$COLOR" = "yes"
    then
        echo -e "\E[1m\E[31m### ${ECHO_UNAME}$*\033[0m"
    else
        echo "### ${ECHO_UNAME}error: $*"
    fi
}


while test $# -gt 0
do
    case "$1" in
      "-color")
        shift
        COLOR=$1
        ;;
      "-uname")
        shift
        SHOW_UNAME=$1
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

if test "$COLOR" != "yes" -a "$COLOR" != "no"
then
    #echo "Color is \"$COLOR\"; setting..."
    if test "`echo "$TERM" | cut -c 1-5`" = "xterm" -o "$TERM" = "rxvt" -o "$TERM" = "konsole"
    then
        COLOR="yes"
    else
        COLOR="no"
    fi
    #echo "Color is $COLOR"
fi

if test "$SHOW_UNAME" = "yes"
then
    ECHO_UNAME="`uname -n`: "
else
    ECHO_UNAME=""
fi
