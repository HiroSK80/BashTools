#!/bin/bash

if test $# = 0
then
    $0 1 2 3 &
    exit
fi

if test "$1" = "end"
then
    while true
    do
        sleep 3
    done
fi

if test $# -eq 1
then
    $0 end $1 &
    while true
    do
        sleep 2
    done
fi

for I in $@
do
    $0 $I &
done

while true
do
    sleep 1
done
