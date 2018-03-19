#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

CONFIG_FILE="tools_example_file_config.config"
set_no PERFORMANCE_DETAILS
function_copy file_config file_config_tools

function file_config
{
    case "$1" in
        prepare)
            file_prepare --empty "$CONFIG_FILE" || echo_error "Can't create `echo_quote "$CONFIG_FILE"` config file" 1
            ;;
        store)
            echo "${@:2}" >> "$CONFIG_FILE"
            ;;
        show)
            cat "$CONFIG_FILE" | pipe_echo_prefix
            ;;
        *)
            file_config_tools "$@"
            ;;
    esac
}

function variables_unset
{
    for VAR in SECTION1_S1V1 SECTION1_S1V2 SECTION1_S1V3 S1V1 S1V2 S1V3 SECTION1_VX SECTION2_VX VX
    do
        for PREFIX in "" "CONFIG_"
        do
            unset $PREFIX$VAR
        done
    done
}

function variables_show
{
    local PREFIX=""
    if test "$1" = "array"
    then
        for VAR in ${PREFIX}SECTION1_S1V1 ${PREFIX}SECTION1_S1V2 ${PREFIX}SECTION1_S1V3 ${PREFIX}S1V1 ${PREFIX}S1V2 ${PREFIX}S1V3 ${PREFIX}SECTION1_VX ${PREFIX}SECTION2_VX ${PREFIX}VX
        do
            echo_line "CONFIG_ARRAY[$VAR]=\"${CONFIG_ARRAY[$VAR]}\""
        done
    else
        test "$1" = "config" && PREFIX="CONFIG_"
        for VAR in ${PREFIX}SECTION1_S1V1 ${PREFIX}SECTION1_S1V2 ${PREFIX}SECTION1_S1V3 ${PREFIX}S1V1 ${PREFIX}S1V2 ${PREFIX}S1V3 ${PREFIX}SECTION1_VX ${PREFIX}SECTION2_VX ${PREFIX}VX
        do
            echo_line "$VAR=\"${!VAR}\""
        done
    fi
}

echo_info "Classic config file:"
file_config prepare
file_config store "S1V1=\"s1v1\""
file_config store "S1V2=\" s1v2 \"  "
file_config store "S1V3=\"\$USER\""
file_config show

echo_info "Classic config file readed with: . \"$CONFIG_FILE\""
variables_unset
performance start
. "$CONFIG_FILE"
performance end
variables_show

echo_info "Extended tools config file:"
file_config prepare
file_config store "[SECTION1]"
file_config store "S1V1=\"s1v1\""
file_config store "  S1V2  =  \" s1v2 \"  "
file_config store "S1V3=\"\$USER\""
file_config store "VX=\"s1vx\""
file_config store "[SECTION2]"
file_config store "VX=\"s2vx\""
file_config show

echo_info "Config file values readed with: file_config get \"$CONFIG_FILE\" S1V1"
variables_unset
performance start
SECTION1_S1V1="`file_config get "$CONFIG_FILE" SECTION1/S1V1`"
SECTION1_S1V2="`file_config get "$CONFIG_FILE" SECTION1/S1V2`"
SECTION1_S1V3="`file_config get "$CONFIG_FILE" SECTION1/S1V3`"
S1V1="`file_config get "$CONFIG_FILE" S1V1`"
S1V2="`file_config get "$CONFIG_FILE" S1V2`"
S1V3="`file_config get "$CONFIG_FILE" S1V3`"
SECTION1_VX="`file_config get "$CONFIG_FILE" SECTION1/VX`"
SECTION2_VX="`file_config get "$CONFIG_FILE" SECTION1/VX`"
VX="`file_config get "$CONFIG_FILE" VX`"
performance end
variables_show

echo_info "Config file values readed with: file_config read \"$CONFIG_FILE\" S1V1"
variables_unset
performance start
file_config read "$CONFIG_FILE" SECTION1/S1V1
file_config read "$CONFIG_FILE" SECTION1/S1V2
file_config read "$CONFIG_FILE" SECTION1/S1V3
file_config read "$CONFIG_FILE" S1V1
file_config read "$CONFIG_FILE" S1V2
file_config read "$CONFIG_FILE" S1V3
file_config read "$CONFIG_FILE" SECTION1/VX
file_config read "$CONFIG_FILE" SECTION2/VX
file_config read "$CONFIG_FILE" VX
performance end
variables_show config

echo_info "Config file values readed with: file_config read --no-eval \"$CONFIG_FILE\" SECTION1/S1V1"
variables_unset
performance start
file_config read --no-eval "$CONFIG_FILE" SECTION1/S1V1
file_config read --no-eval "$CONFIG_FILE" SECTION1/S1V2
file_config read --no-eval "$CONFIG_FILE" SECTION1/S1V3
file_config read --no-eval "$CONFIG_FILE" S1V1
file_config read --no-eval "$CONFIG_FILE" S1V2
file_config read --no-eval "$CONFIG_FILE" S1V3
file_config read --no-eval "$CONFIG_FILE" SECTION1/VX
file_config read --no-eval "$CONFIG_FILE" SECTION2/VX
file_config read --no-eval "$CONFIG_FILE" VX
performance end
variables_show config

echo_info "Config file setting values"
variables_unset
performance start
file_config set "$CONFIG_FILE" SECTION1/VX "t1"
file_config set "$CONFIG_FILE" SECTION2/VX "t2"
file_config set "$CONFIG_FILE" SECTION3/VX "t3"
file_config set "$CONFIG_FILE" VX "tx"
performance end
file_config show
file_config read --no-eval "$CONFIG_FILE" SECTION1/S1V1
file_config read --no-eval "$CONFIG_FILE" SECTION1/S1V2
file_config read --no-eval "$CONFIG_FILE" SECTION1/S1V3
file_config read --no-eval "$CONFIG_FILE" S1V1
file_config read --no-eval "$CONFIG_FILE" S1V2
file_config read --no-eval "$CONFIG_FILE" S1V3
file_config read --no-eval "$CONFIG_FILE" SECTION1/VX
file_config read --no-eval "$CONFIG_FILE" SECTION2/VX
file_config read --no-eval "$CONFIG_FILE" VX
variables_show config

echo_info "Config file loaded to variables"
variables_unset
performance start
file_config load --to-variables "$CONFIG_FILE"
performance end
variables_show config

echo_info "Config file loaded to array"
variables_unset
performance start
declare -A CONFIG_ARRAY
file_config load "$CONFIG_FILE" --to-array CONFIG_ARRAY
performance end
echo "CONFIG_ARRAY=${CONFIG_ARRAY[@]}"
variables_show array
