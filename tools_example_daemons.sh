#!/bin/bash

export TOOLS_FILE="$(dirname "$0")/tools.sh"
source "$TOOLS_FILE" --debug "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }
debug set event
debug set daemon

function daemon_running_message
{
    test $? -eq 0 && print "Daemon $DAEMON_NAME running as $DAEMON_PID" || print "Daemon $DAEMON_NAME not running"
}

if test_cmd_z
then
    print info "Usage: $0 <command> <option>"
    print info "Commands:"
    print step "  start - start all daemons"
    print step "  stop - stop all daemons"
    print step "  kill - kill all daemons"
    print step "  status - show daemons status"
fi

if test_cmd "start"
then
    daemon status && print "Daemon $DAEMON_NAME already running" && exit
    # calling script to run as daemon on background with additional daemons
    $0 daemon &
    $0 daemon 1 &
    $0 daemon 2 &
fi

if test_cmd "stop"
then
    daemon status && daemon stop
    daemon status "$SCRIPT_NAME_NOEXT-1" && daemon stop "$SCRIPT_NAME_NOEXT-1"
    daemon status "$SCRIPT_NAME_NOEXT-2" && daemon stop "$SCRIPT_NAME_NOEXT-2"
fi

if test_cmd "kill"
then
    daemon status && daemon kill
    daemon status "$SCRIPT_NAME_NOEXT-1" && daemon kill "$SCRIPT_NAME_NOEXT-1"
    daemon status "$SCRIPT_NAME_NOEXT-2" && daemon kill "$SCRIPT_NAME_NOEXT-2"
fi

if test_cmd "daemon"
then
    if test_opt_z
    then
        daemon init
        print "Daemon $DAEMON_NAME started, work time 20s"
        for I in $(seq 1 20)
        do
            daemon loop || { print "Daemon $DAEMON_NAME loop break"; break; }
            sleep 1
        done
        print "Daemon $DAEMON_NAME finished"
        daemon done
    else
        D="$SCRIPT_NAME_NOEXT-$OPTION"
        daemon init "$D"
        declare -i N=20
        let N="N+2*$OPTION"
        print "Daemon $DAEMON_NAME started, work time ${N}s"
        for I in $(seq 1 $N)
        do
            daemon loop || { print "Daemon $DAEMON_NAME loop break"; break; }
            sleep 1
        done
        print "Daemon $DAEMON_NAME finished"
        daemon done "$DAEMON_NAME"
    fi
fi

if test_cmd "^(|status)$"
then
    daemon status
    daemon_running_message
    daemon status "$SCRIPT_NAME_NOEXT-1"
    daemon_running_message
    daemon status "$SCRIPT_NAME_NOEXT-2"
    daemon_running_message
fi
