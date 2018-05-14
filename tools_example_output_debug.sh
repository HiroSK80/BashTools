#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

debug init_namespaces
# shorten "tools_example_output_debug[.sh]" labels into "this[.sh]"
FUNCTION_NAMESPACES[main]="this.sh"
FUNCTION_NAMESPACES[function_1]="this/f1"
FUNCTION_NAMESPACES[function_2]="this/f2"

function function_2
{
    print step "Second function called from function_abc"
    print debug --function "$@"
}

function function_1
{
    print step "First function called from main"
    print debug --function "$@"
    function_2 arg_c arg_d
}

print debug --right "here is sample right aligned debug"
print info "Testing simple debug information"
print debug "Debug message"
print debug --variable HOSTNAME BASH NO_VARIABLE

print info "Testing functions debug information"
print step "Main called from command line"
print debug --function "$@"
function_1 arg_a arg_b

print info "Testing advanced debugging"
print step "Preconfigured debug level values"
print debug --variable DEBUG_LEVEL DEBUG_LEVEL_STR
print debug --variable DEBUG_LEVEL_DEFAULT DEBUG_LEVEL_DEFAULT_STR
debug set yes variable function
print step "Setting debug type to: $DEBUG_TYPE"
debug set_level INFO # will not show DEBUG TRACE ALL
print step "Setting debug level to: $DEBUG_LEVEL / $DEBUG_LEVEL_STR"
print debug ALL "all=100"
print debug TRACE "trace=90"
print debug DEBUG "debug=80"
print debug INFO "info=50"
print debug WARN "warn=30"
print debug ERROR "error=20"
print debug FATAL "fatal=10"
print debug FORCE "force=1"
print debug OFF "off=0"
print debug "default"
print debug --variable DEBUG_LEVEL DEBUG_LEVEL_STR
debug set_level ALL

print info "Testing command debugging"
print debug --custom command "Debug \"command\" messages are yet enabled"
debug set command
call_command date
print debug --custom command "Debug \"command\" messages are enabled"

print info "Testing custom debugging with possible combinations of debug level, debug type, debug message"
print debug --custom customX "Debug \"customX\" messages are yet enabled"
DEBUG_TYPES[customX]="X"
debug set customX
print debug --custom customX "Debug \"customX\" messages are enabled [default level]"
print debug --custom customX INFO "Debug \"customX\" messages are enabled [INFO level]"
print debug --custom customX INFO -- "Debug \"customX\" messages are enabled [safe message string]"
print debug --custom customX -- INFO "Debug \"customX\" messages are enabled [all arguments as message]"
