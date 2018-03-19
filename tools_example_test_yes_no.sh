#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

function test_simple
{
    echo_substep "yes  \c" && test_$1 yes && echo true || echo false
    echo_substep "no   \c" && test_$1 no && echo true || echo false
}

function test_referenced
{
    echo_substep "\$A   \c" && test_$1 "$A" && echo true || echo false
    echo_substep "A    \c" && test_$1 A && echo true || echo false
    echo_substep "\$AA  \c" && test_$1 "$AA" && echo true || echo false
    echo_substep "AA   \c" && test_$1 AA && echo true || echo false
}

echo_info "Simple"
echo_step "test_yes"
test_simple yes
echo_step "test_no"
test_simple no

set_yes A
AA="A"
echo_info "Referenced"
echo_step "test_yes for A=\"$A\"; AA=\"$AA\""
test_referenced yes
echo_step "test_no for A=\"$A\"; AA=\"$AA\""
test_referenced no

set_no A
AA="A"
echo_step "test_yes for A=\"$A\"; AA=\"$AA\""
test_referenced yes
echo_step "test_no for A=\"$A\"; AA=\"$AA\""
test_referenced no
