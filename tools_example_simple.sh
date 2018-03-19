#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

echo_info "Script arguments"
echo_quote "$@"
echo_step "command: $COMMAND"
echo_step "option: $OPTION"

echo_info "Running tools processes"
echo_debug_right "show formatted command output (with logging)"
ps -ef | grep "$0" | pipe_echo_prefix
