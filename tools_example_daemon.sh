#!/bin/bash

export TOOLS_FILE="$(dirname "$0")/tools.sh"
source "$TOOLS_FILE" --debug "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }
debug set event
debug set daemon

if test_cmd_z
then
    print info "Usage: $0 <command> <option>"
    print info "Commands:"
    print step "  start - start daemon"
    print step "  stop - stop daemon"
    print step "  kill - kill daemon"
    print step "  status - show daemon status"
fi

if test_cmd "start"
then
    daemon status && print "Daemon $DAEMON_NAME already running" && exit
    # calling script to run as daemon on background with additional daemons
    $0 daemon &
fi

if test_cmd "stop"
then
    daemon status && daemon stop
fi

if test_cmd "kill"
then
    daemon status && daemon kill
fi

if test_cmd "daemon"
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
fi

if test_cmd "^(|status)$"
then
    daemon status && print "Daemon $DAEMON_NAME running as $DAEMON_PID" || print "Daemon $DAEMON_NAME not running"
fi
