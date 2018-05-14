#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" --debug || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

print info "Script arguments"
print quote "$@"
print step "command: $COMMAND"
print step "option: $OPTION"

print debug --right "show formatted command output (with logging)"
print info "Running tools processes"
ps -ef | grep "$0" | pipe prefix
