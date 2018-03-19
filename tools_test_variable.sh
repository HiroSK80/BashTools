#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

function show_A
{
    echo_line "\$A=$A"
    echo_line "\${A:a}=${A:a}       ${S_TAB}without function"
    echo_line "\${A-a}=${A-a}       ${S_TAB}a=not exist"
    echo_line "\${A:-a}=${A:-a}     ${S_TAB}a=not exist or empty"
    echo_line "\${A+a}=${A+a}       ${S_TAB}a=exist"
    echo_line "\${A:+a}=${A:+a}     ${S_TAB}a=exist and not empty"
}

function show_1
{
    echo_line "\$1=$1"
    echo_line "\${!1}=${!1}"
    echo_line "\${!1:a}=${!1:a}     ${S_TAB}without function"
    echo_line "\${!1-a}=${!1-a}     ${S_TAB}a=not exist"
    echo_line "\${!1:-a}=${!1:-a}   ${S_TAB}a=not exist or empty"
    echo_line "\${!1+a}=${!1+a}     ${S_TAB}a=exist"
    echo_line "\${!1:+a}=${!1:+a}   ${S_TAB}a=exist and not empty"
}

echo_info "unset A"
unset A
show_A
show_1 A

echo_info "set A=\"\""
A=""
show_A
show_1 A

echo_info "set A=\"x\""
A="x"
show_A
show_1 A

echo_info "testing global/local/export/declare"

function funct2
{
    echo_line "funct2 GLOBAL=$GLOBAL"
    echo_line "funct2 FUNCT1=$FUNCT1"
    FUNCT1="redefined from funct2"
}

function funct1
{
    local FUNCT1="local funct1 variable"
    export EXPORTED1="exported from funct1 with export"
    declare -x EXPORTED2="exported from funct1 with declare -x"
    declare -a GLOBAL_ARRAY1=(global array from funct1 with "declare -a" will not go main)
    GLOBAL_ARRAY2=(global array from funct1)
    NORMAL="normal defined from funct1"
    echo_line "funct1 GLOBAL=$GLOBAL"
    echo_line "funct1 GLOBAL_ARRAY1=${GLOBAL_ARRAY1[@]}"
    echo_line "funct1 GLOBAL_ARRAY2=${GLOBAL_ARRAY2[@]}"
    echo_line "funct1 FUNCT1=$FUNCT1"
    echo_line "funct1 EXPORTED1=$EXPORTED1"
    echo_line "funct1 EXPORTED2=$EXPORTED2"
    echo_line "funct1 NORMAL=$NORMAL"
    funct2
    echo_line "funct1 FUNCT1=$FUNCT1"
}

GLOBAL="global variable in main"
declare -a GLOBAL_ARRAY1=(global array)
declare -a GLOBAL_ARRAY2=(global array)
echo_line "main GLOBAL=$GLOBAL"
echo_line "main GLOBAL_ARRAY1=${GLOBAL_ARRAY1[@]}"
echo_line "main GLOBAL_ARRAY2=${GLOBAL_ARRAY2[@]}"
funct1
echo_line "main GLOBAL_ARRAY1=${GLOBAL_ARRAY1[@]}"
echo_line "main GLOBAL_ARRAY2=${GLOBAL_ARRAY2[@]}"
echo_line "main FUNCT1=$FUNCT1"
echo_line "main EXPORTED1=$EXPORTED1"
echo_line "main EXPORTED2=$EXPORTED2"
echo_line "main NORMAL=$NORMAL"

echo_info "testing custom arrays"
for ARRAY_STR in "(\"a1 a2\" b c)" "[a1 a2,b,c]" "{a1 a2:b:c}"
do
    str_array_convert ARRAY_CONV "$ARRAY_STR"
    echo "$ARRAY_STR=$ARRAY_CONV"
done

array_assign ARRAY "`str_array_convert "{a1 a2:b:c}"`"
echo "ARRAY=${ARRAY[@]}"
echo "ARRAY[0]=${ARRAY[0]}"
echo "ARRAY[1]=${ARRAY[1]}"
echo "ARRAY[2]=${ARRAY[2]}"
