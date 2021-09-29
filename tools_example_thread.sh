#!/bin/bash
source "$(dirname $0)/tools.sh"

function test_thread
{
    sleep 2
    while true
    do
        thread loop || break
        print "test_thread running"
        sleep 1
    done
}

thread init

print info "Starting"
thread start test_thread
print info "Waiting 10s"
sleep 10
print info "Stopping"
thread stop test_thread
thread wait ALL && print step "Done" || print step "Done, running on background"

thread done
