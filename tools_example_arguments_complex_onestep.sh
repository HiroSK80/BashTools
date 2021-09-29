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
SIZE=0

# simplified check - buffered checks and processed in one step brings some limitations:
#   - unsupported commands joined with && after check: arguments onestep switch "S|switch" "SWITCH|yes" && echo "Switch set"
arguments onestep switch "S|switch" "SWITCH|yes"
arguments onestep switch "a" "SWITCH_A|yes"
arguments onestep switch "b" "SWITCH_B|yes"
arguments onestep switch "c" "SWITCH_C|yes"
arguments onestep switch "v|verbose" "VERBOSE||increase"
arguments onestep value  "V|value" "VALUE"
arguments onestep value  "h|host" "HOST/append|ping"
arguments onestep value  s"|size" "SIZE|human"
arguments onestep option "COMMAND|(start stop test)"
arguments onestep option "FILE/array|file_read file_canonicalize"
arguments onestep run "$@"

if test_cmd_z
then
    EXAMPLE_CALL="$0 test -S -vvv --value=val $SCRIPT_NAME -h localhost --host `get_ip` -bvca $TOOLS_FILE"
    print info "Usage: $SCRIPT_NAME [options] <command> [options] [file1] [file2...] [options]"
    print "Command: <start|stop|test>"
    print "Options: -S | --switch | -a | -b | -c        multiple switch usage supported: -sabc"
    print "         -v | --verbose                      multiple verbose options supported to increase verbose"
    print "         -V <value> | --value=<value> | --value <value>"
    print "         -h <host> | --host=<host> | --host <host>"
    print "         -s <size> | --size=<size>           assign integer value and recognize human readable value like 100k (=x1000) 20M (=x1024x1024)..."
    print
    print info "Example call: $EXAMPLE_CALL"
    print
    $EXAMPLE_CALL
    exit
fi

print info "You specified arguments"
print step "command:\t\t$COMMAND"
test "${#FILE[@]}" -ne 0 && print step "file(s):\t\t${#FILE[@]} = ${FILE[*]}" || print step "file:\t\t\tnot specified"
test_yes SWITCH && print step "switch is:\t\tset" || print step "switch is:\t\tnot set"
print step "switch a b c:\t\t$SWITCH_A  $SWITCH_B  $SWITCH_C"
print step "verbose level:\t$VERBOSE"
print step "option value:\t\t$VALUE"
print step "host(s):\t\t$HOST"
print step "option size:\t\t$SIZE"
