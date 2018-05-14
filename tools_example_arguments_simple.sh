#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

# . "$TOOLS_FILE" "$@"
# is almost (with removed known arguments to tools) equal to `command_options fill "$@"`

if test_help || test_cmd_z
then
    echo "Usage \"$0 e|example\""
    exit
fi

if test_cmd "^(e|example)$"
then
    print info "This is example command $COMMAND"
    print step "Here we will do some task"
fi
