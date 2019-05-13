#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right --debug-command "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

function test_function
{
    print debug --function "$@"
    print warning --function "$@" "FUNCTION WARNING"
    print error --function "$@" "ERROR"
}

#set_no LOG_WITHDATE
log init

print title --center "CENTERED ${COLOR_RED}TITLE"
print info "INFO"
print step "STEP"
print "LEFT ALIGNED LINE" # equal to: print line --align=left "LEFT ALIGNED LINE"
print --center "CENTER ALIGNED LINE"
print --right "RIGHT ALIGNED LINE"
# "log echo" function store message only to log file
log echo "LOG"

print step "STEP"
SN=1
SA=a
print step SN "STEP1"
print step SN "STEP2"
print step SA "STEPa"
print step SA "STEPb"

print substep "SUBSTEP"

print warning "WARNING"
print warning --function "FUNCTION WARNING"
print error "ERROR"
print error --function "FUNCTION ERROR"
print debug --right "DEBUG RIGHT"
print debug "DEBUG"
print debug --variable TOOLS_FILE BASH_VERSINFO
print debug --right --variable HOSTNAME

print
print info "Function examples"
test_function ARG1 ARG2

print
print info "Pipe examples"
# log output only
ls -l "$0" | pipe_log
# show and log output
ls -l "$0" | pipe_echo
# show and log output with prefix
ls -l "$0" | pipe_echo_prefix

log done
