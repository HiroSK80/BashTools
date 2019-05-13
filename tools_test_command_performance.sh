#!/bin/bash

export TOOLS_FILE="$(dirname $0)/tools.sh"
source "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

set_no PERFORMANCE_DETAILS

print info "Example simple echo command"
performance start "" "echo"
for I in {1..1000}
do
    echo > /dev/null
done
performance end

for COMMAND in "date" "declare -p I" "echo"
do
    print info "Testing command: $COMMAND"

    performance start "" "$COMMAND"
    for I in {1..1000}
    do
        $COMMAND > /dev/null
    done
    performance end

    performance start "" "eval \"$COMMAND\""
    for I in {1..1000}
    do
        eval "$COMMAND" > /dev/null
    done
    performance end

    performance start "" "LINE=\`$COMMAND\`"
    for I in {1..1000}
    do
        LINE="`$COMMAND`" > /dev/null
    done
    performance end

    performance start "" "LINE=\$($COMMAND)"
    for I in {1..1000}
    do
        LINE="$($COMMAND)" > /dev/null
    done
    performance end

    performance start "" "read LINE < <($COMMAND)"
    for I in {1..1000}
    do
        read LINE < <($COMMAND)
    done
    #echo $LINE
    performance end

    performance start "" "{ read LINE; } < <($COMMAND)"
    for I in {1..1000}
    do
        { read LINE; } < <($COMMAND)
    done
    #echo $LINE
    performance end

    performance start "" "{ read LINE; } < <(eval $COMMAND)"
    for I in {1..1000}
    do
        { read LINE; } < <(eval "$COMMAND")
    done
    #echo $LINE
    performance end

    performance start "" "$COMMAND | ( read LINE )"
    for I in {1..1000}
    do
        $COMMAND | ( read LINE )
    done
    #echo $LINE
    performance end

done
