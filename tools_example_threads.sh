#!/bin/bash
source "$(dirname $0)/tools.sh"

function thread1
{
    local I=0
    sleep 2
    while true
    do
        thread data "$I"
        thread loop || { sleep 5; break; }
        #echo -n "thread1 $1 running THREAD_TASK=$THREAD_TASK"
        sleep 1
        let I++
    done
}

function thread2
{
    local I=0
    sleep 2
    while true
    do
        #thread data "$I,alias=${THREAD_INFO[ALIAS]},name=${THREAD_INFO[NAME]},args=${THREAD_INFO[ARGUMENTS]},cmd=${THREAD_INFO[COMMAND]},real_args1=$1,real_args2=$2"
        thread data "$I,alias=${THREAD_INFO[ALIAS]},name=${THREAD_INFO[NAME]},args=${THREAD_INFO[ARGUMENTS]}|$(print quote "$@"),cmd=${THREAD_INFO[COMMAND]}"
        thread loop || { sleep 5; break; }
        #echo -n "thread2 running THREAD_TASK=$THREAD_TASK"
        sleep 1
        let I++
    done
}

#function thread_test
#{
#    sleep 5
#}
#
#test $# = 1 && $1 && exit
#
#ps -ef | grep thread
#exec $0 thread_test &
#ps -ef | grep thread
#exit


THREAD_NO=1
THREAD_CALL="thread1"
THREAD_ARGS="thread1"
thread init
cursor hide
while true
do
    thread checks

    echo -n "THREAD_ALIAS="
    for PID in "${!THREAD_ALIAS[@]}"
    do
        echo -n "$PID:${THREAD_ALIAS[$PID]}  "
    done
    terminal clear line right
    echo

    echo -n "THREAD_NAME="
    for PID in "${!THREAD_NAME[@]}"
    do
        echo -n "$PID:${THREAD_NAME[$PID]}  "
    done
    terminal clear line right
    echo

    echo -n "THREAD_COMMAND="
    for PID in "${!THREAD_COMMAND[@]}"
    do
        echo -n "$PID:${THREAD_COMMAND[$PID]}  "
    done
    terminal clear line right
    echo

    echo -n "THREAD_ARGUMENTS="
    for PID in "${!THREAD_ARGUMENTS[@]}"
    do
        echo -n "$PID:${THREAD_ARGUMENTS[$PID]}  "
    done
    terminal clear line right
    echo

    echo -n "THREAD_PID="
    for ALIAS in "${!THREAD_PID[@]}"
    do
        echo -n "$ALIAS:${THREAD_PID[$ALIAS]}  "
    done
    terminal clear line right
    echo

    echo -n "THREAD_STATUS="
    for PID in "${!THREAD_STATUS[@]}"
    do
        echo -n "$PID:${THREAD_STATUS[$PID]}  "
    done
    terminal clear line right
    echo

    echo -n "THREAD_DATA="
    for PID in "${!THREAD_DATA[@]}"
    do
        echo -n "$PID:${THREAD_DATA[$PID]}  "
    done
    terminal clear line right
    echo

    echo -n "controlling $THREAD_NO: $THREAD_CALL {=$THREAD_ARGS} $(thread status $THREAD_CALL) $(thread exist $THREAD_CALL && echo "exist" || echo "not exist") $(thread active $THREAD_CALL && echo "active" || echo "not active")   "
    print waiter
    terminal clear line right

    TASK=""
    read -s -n 1 -t 0.1 TASK
    test "$TASK" = "1" && THREAD_NO=1 && THREAD_CALL="thread1" && THREAD_ARGS="thread1"
    test "$TASK" = "2" && THREAD_NO=1 && THREAD_CALL="--alias=t1 thread1" && THREAD_ARGS="t1"
    test "$TASK" = "3" && THREAD_NO=2 && THREAD_CALL="--alias=t2 thread2 param A" && THREAD_ARGS="t2"
    test "$TASK" = "4" && THREAD_NO=2 && THREAD_CALL="--alias=t2b thread2 \"param A\"" && THREAD_ARGS="t2b"
    test "$TASK" = "a" && eval "thread start $THREAD_CALL"
    test "$TASK" =  s  && thread stop $THREAD_ARGS
    test "$TASK" =  S  && thread stop ALL
    test "$TASK" = "k" && thread kill $THREAD_ARGS
    test "$TASK" = "p" && thread pause $THREAD_ARGS
    test "$TASK" = "r" && thread resume $THREAD_ARGS
    test "$TASK" = "x" && cursor left 4 && terminal clear line right && break
    cursor up 7
    echo -e -n "\r"
done
echo
cursor show

print info "Finishing"
print step "Stopping"
thread stop ALL
print step "Waiting"
thread wait ALL && print step "Done" || print step "Done, $? running on background"
thread done

exit
