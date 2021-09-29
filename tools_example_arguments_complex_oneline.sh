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
arguments oneline value  s"|size" "SIZE|human"
arguments oneline option "COMMAND|(start stop test)"
arguments oneline option "FILE/array|file_read file_canonicalize"
arguments oneline unknown

if test_cmd_z
then
    EXAMPLE_CALL="$0 test -S -vvv --value=val $SCRIPT_NAME -h localhost --host `get_ip` -bvca $TOOLS_FILE --size=10M"
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
