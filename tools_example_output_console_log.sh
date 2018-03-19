#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right --debug-command "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

log init

function test_function
{
    echo_debug_function "$@"
    echo_error_function "ERROR"
}

# all echo_* functions are logged and shown on console except "log echo" function
echo_title "TITLE"
echo_info "INFO"
echo_step "STEP"
echo_line "LINE"
log echo "LOG"

SN=1
SA=a
echo_step SN "STEP1"
echo_step SN "STEP2"
echo_step SA "STEPa"
echo_step SA "STEPb"

echo_substep "SUBSTEP"
echo_warning "WARNING"
echo_error "ERROR"
echo_error_function "FUNCTION ERROR"
echo_debug_right "DEBUG RIGHT"
echo_debug "DEBUG"
echo_debug_variable HOSTNAME TOOLS_FILE BASH_VERSINFO
test_function ARG1 ARG2

# log output only
ls -l "$0" | pipe_log
# show and log output
ls -l "$0" | pipe_echo
# show and log output with prefix
ls -l "$0" | pipe_echo_prefix

log done
