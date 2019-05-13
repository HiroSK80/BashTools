#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
source "$TOOLS_FILE" --debug "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

# EXIT INT QUIT TERM

function event_on_exit
{
    print "Event signal EXIT"
}

function event_on_int
{
    print "Event signal INT"
}

function event_on_quit
{
    print "Event signal QUIT"
}

function event_on_term
{
    print "Event signal TERM"
}

function trap_on_exit
{
    print "Trap signal EXIT"
}

function trap_on_term
{
    print "Trap signal TERM"
}

event add EXIT "event_on_exit"
event add INT "event_on_int"
event add QUIT "event_on_quit"
event add TERM "event_on_term"

trap '' EXIT
trap trap_on_exit EXIT
trap trap_on_term TERM

kill $$

echo "Dead code"
