#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

COMMAND=""
declare -a FILE
HOST=""
SWITCH="no"
SWITCH_A="no"
SWITCH_B="no"
SWITCH_C="no"
VERBOSE="0"
VALUE="none"

# simplified check - buffered checks and processed in one step brings some limitations:
#   - unsupported commands joined with && after check: arguments onestep switch "S|switch" "SWITCH|yes" && echo "Switch set"
arguments onestep switch "S|switch" "SWITCH|yes"
arguments onestep switch "a" "SWITCH_A|yes"
arguments onestep switch "b" "SWITCH_B|yes"
arguments onestep switch "c" "SWITCH_C|yes"
arguments onestep switch "v|verbose" "VERBOSE||increase"
arguments onestep value  "V|value" "VALUE"
arguments onestep value  "h|host" "HOST/append|ping"
arguments onestep option "COMMAND|(start stop test)"
arguments onestep option "FILE/array|file_read file_canonicalize"
arguments onestep run "$@"

if test_cmd_z
then
    EXAMPLE_CALL="$0 test -S -vvv --value=val $SCRIPT_NAME -h localhost --host `get_ip` -bvca $TOOLS_FILE"
    echo_info "Usage: $SCRIPT_NAME [options] <command> [options] [file1] [file2...] [options]"
    echo_line "Command: <start|stop|test>"
    echo_line "Options: -S | --switch | -a | -b | -c        multiple switch usage supported: -sabc"
    echo_line "         -v | --verbose                      multiple verbose options supported to increase verbose"
    echo_line "         -V <value> | --value=<value> | --value <value>"
    echo_line "         -h <host> | --host=<host> | --host <host>"
    echo_line
    echo_info "Example call: $EXAMPLE_CALL"
    echo_line
    $EXAMPLE_CALL
    exit
fi

echo_info "You specified arguments"
echo_step "command:\t\t$COMMAND"
test "${#FILE[@]}" -ne 0 && echo_step "file(s):\t\t${#FILE[@]} = ${FILE[*]}" || echo_step "file:\t\t\tnot specified"
test_yes SWITCH && echo_step "switch is:\t\tset" || echo_step "switch is:\t\tnot set"
echo_step "switch a b c:\t\t$SWITCH_A  $SWITCH_B  $SWITCH_C"
echo_step "verbose level:\t$VERBOSE"
echo_step "option value:\t\t$VALUE"
echo_step "host(s):\t\t$HOST"
