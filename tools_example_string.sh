#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

echo_info "Example cut function"

TABS="`echo -e "${COLOR_DARK_GRAY}123456789|123456789|123456789|123456789|123456789|123456789${COLOR_RESET}"`"
STRING="`echo -e "012345678901234567890123456789012345678901234567890123456789\nabcdefghijklmnopqrstuvwxyz"`"

echo_line "$TABS"
echo "$STRING" | pipe_cut center 20

echo_line "$TABS"
echo "$STRING" | pipe_cut left 20
echo_cut left 20 "$STRING"

echo_line "$TABS"
echo "$STRING" | pipe_cut right 20

echo_info "Example string with words function"

A="1 2 3"
str_delete_word A 1
echo_debug_variable A

A="1 2 3"
str_delete_word A 2
echo_debug_variable A

A="1 2 3"
str_delete_word A 3
echo_debug_variable A

str_delete_word "1 2 3" 1
echo
str_delete_word "1 2 3" 2
echo
str_delete_word "1 2 3" 3
echo
