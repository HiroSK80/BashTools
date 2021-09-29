#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
source "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

function test_function
{
    print "test"
}

test_function

#./tools.sh --execute "tools_union tools_example_union.sh tools_example_unioned.sh"