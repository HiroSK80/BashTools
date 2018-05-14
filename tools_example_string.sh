#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

print info "Example cut function"
TABS="`echo -e "${COLOR_DARK_GRAY}123456789|123456789|123456789|123456789|123456789|123456789${COLOR_RESET}"`"
STRING="`echo -e "012345678901234567890123456789012345678901234567890123456789\nabcdefghijklmnopqrstuvwxyz"`"
for TYPE in center left right
do
    print "$TABS"
    print "$STRING" | pipe cut "$TYPE" 20
    test "$TYPE" = "center" && print cut center 20 "$STRING"
done

print info "Example string with words function"
for I in 1 2 3
do
    A="1 2 3"
    str_word add A "1" # will not be added as already present
    print debug --variable A
    str_word delete A "$I"
    print debug --variable A
    str_word delete "1 2 3" "$I" && echo # it also works on string
    str_word check A "1" && echo "1 is present"
    echo
done
