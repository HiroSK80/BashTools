#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }


function testfiles_prepare
{
    rm -f TestFile*
    echo "o" > TestFile
    for I in 1 2 3 4 5 6 7 8 9 10 11
    do
        echo "$I" > TestFile-$I
    done
}

function testfiles_show
{
#    file_loop "TestFile*" << 'EOF'
#echo -e "    $FILE\\t`cat $FILE`"
#EOF
    file_loop "TestFile*" 'echo -e "    $FILE\t`cat $FILE`"'
}


echo_info "Rolling old files example"

testfiles_prepare
echo_step "Files before"
testfiles_show

# default old files count = 9
file_prepare -r "TestFile"

echo_step "Files after"
testfiles_show
