#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

echo_info "Current shell forest"
ps -o ppid,pid,cmd --forest

echo_info "PIDs to kill"
get_pids_tree "1 2 3"

echo_info "Killing"
kill_tree "1 2 3"
