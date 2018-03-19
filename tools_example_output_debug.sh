#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

# shorten "tools_example_output_debug[.sh]" labels into "this[.sh]"
FUNCTION_NAMESPACES[main]="this.sh"
FUNCTION_NAMESPACES[function_1]="this/f1"
FUNCTION_NAMESPACES[function_2]="this/f2"

function function_2
{
    echo_step "Second function called from function_abc"
    echo_debug_function "$@"
}

function function_1
{
    echo_step "First function called from main"
    echo_debug_function "$@"
    function_2 arg_c arg_d
}

echo_debug_right "here is sample right aligned debug"
echo_info "Testing simple debug information"
echo_debug "Debug message"
echo_debug_variable HOSTNAME BASH NO_VARIABLE

echo_info "Testing functions debug information"
echo_step "Main called from command line"
echo_debug_function "$@"
function_1 arg_a arg_b

echo_info "Testing advanced debugging"
echo_step "Preconfigured debug level values"
echo_debug_variable DEBUG_LEVEL DEBUG_LEVEL_STR
echo_debug_variable DEBUG_LEVEL_DEFAULT DEBUG_LEVEL_DEFAULT_STR
debug set yes right variable function
echo_step "Setting debug type to: $DEBUG_TYPE"
debug set_level INFO # will not show DEBUG TRACE ALL
echo_step "Setting debug level to: $DEBUG_LEVEL / $DEBUG_LEVEL_STR"
echo_debug ALL "all=100"
echo_debug TRACE "trace=90"
echo_debug DEBUG "debug=80"
echo_debug INFO "info=50"
echo_debug WARN "warn=30"
echo_debug ERROR "error=20"
echo_debug FATAL "fatal=10"
echo_debug FORCE "force=1"
echo_debug OFF "off=0"
echo_debug "default"
echo_debug_variable DEBUG_LEVEL DEBUG_LEVEL_STR

echo_info "Testing command debugging"
echo_debug_custom command INFO "Debug \"command\" messages are yet enabled"
debug set command
call_command date
echo_debug_custom command INFO "Debug \"command\" messages are enabled"

echo_info "Testing custom debugging with possible combinations of debug level, debug type, debug message"
debug set_level ALL
echo_debug_custom customX "Debug \"customX\" messages are yet enabled"
DEBUG_TYPES[customX]="X"
debug set customX
echo_debug_custom customX "Debug \"customX\" messages are enabled [default level]"
echo_debug_custom customX INFO "Debug \"customX\" messages are enabled [INFO level]"
echo_debug_custom customX INFO -- "Debug \"customX\" messages are enabled [safe message string]"
echo_debug_custom customX -- INFO "Debug \"customX\" messages are enabled [all arguments as message]"
