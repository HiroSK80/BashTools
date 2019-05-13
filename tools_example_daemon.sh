#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
source "$TOOLS_FILE" --debug --debug-variable "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }
debug set event
debug set daemon

function daemon_running_message
{
    test $? -eq 0 && print "Daemon $DAEMON_NAME running as $DAEMON_PID" || print "Daemon $DAEMON_NAME not running"
}

if test_cmd_z
then
    echo "$0 <command> <option>"
    echo "  start"
fi

if test_cmd "start"
then
    daemon status && print "Daemon $DAEMON_NAME already running" && exit
    # calling script to run as daemon on background with additional daemons
    $0 daemon &
    $0 daemon 1 &
    $0 daemon 2 &
    exit
fi

if test_cmd "stop"
then
    daemon status && daemon stop
    daemon status "$SCRIPT_NAME_NOEXT-1" && daemon stop "$SCRIPT_NAME_NOEXT-1"
    daemon status "$SCRIPT_NAME_NOEXT-2" && daemon stop "$SCRIPT_NAME_NOEXT-2"
    exit
fi

if test_cmd "kill"
then
    daemon status && daemon kill
    daemon status "$SCRIPT_NAME_NOEXT-1" && daemon kill "$SCRIPT_NAME_NOEXT-1"
    daemon status "$SCRIPT_NAME_NOEXT-2" && daemon kill "$SCRIPT_NAME_NOEXT-2"
    exit
fi

if test_cmd "daemon"
then
    if test_opt_z
    then
        daemon init
        print "Daemon $SCRIPT_NAME_NOEXT started, work time 20"
        for I in $(seq 1 20)
        do
            daemon loop || break
            sleep 1
        done
        print "Daemon $SCRIPT_NAME_NOEXT finished"
        daemon done
    else
        D="$SCRIPT_NAME_NOEXT-$OPTION"
        daemon init "$D"
        declare -i N=20
        let N="N+2*$OPTION"
        print "Daemon $D started, work time $N"
        for I in $(seq 1 $N)
        do
            daemon loop || break
            sleep 1
        done
        print "Daemon $D finished"
        daemon done "$D"
    fi
    exit
fi

daemon status
daemon_running_message
daemon status "$SCRIPT_NAME_NOEXT-1"
daemon_running_message
daemon status "$SCRIPT_NAME_NOEXT-2"
daemon_running_message
