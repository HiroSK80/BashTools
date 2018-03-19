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

# simplified check - as all arguments are checked in one line it brings some limitations:
#   - all switches need to be before options check to eliminate them
#   - in this case option for unknown switch (--unknown "option") is recognized as FILE option
arguments oneline switch "S|switch" "SWITCH|yes" "$@"
arguments oneline switch "a" "SWITCH_A|yes"
arguments oneline switch "b" "SWITCH_B|yes"
arguments oneline switch "c" "SWITCH_C|yes"
arguments oneline switch "v|verbose" "VERBOSE||increase"
arguments oneline value  "V|value" "VALUE"
arguments oneline value  "h|host" "HOST/append|ping"
arguments oneline option "COMMAND|(start stop test)"
arguments oneline option "FILE/array|file_read file_canonicalize"
arguments oneline unknown

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
