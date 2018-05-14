#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

FILE_TEST="TestFile"

function testfiles
{
    case "$1" in
        prepare)
            rm -f "$FILE_TEST"*
            echo "o" > "$FILE_TEST"
            for I in 1 2 3 4 5 6 7 8 9 10 11
            do
                echo "$I" > "$FILE_TEST-$I"
            done
        ;;
        show)
            #    file_loop "TestFile*" << 'EOF'
            #echo -e "    $FILE\\t`cat $FILE`"
            #EOF
            file_loop "$FILE_TEST*" 'echo -e "    $FILE\t`cat $FILE`"'
        ;;
        delete)
            rm -f "$FILE_TEST"*
        ;;
    esac
}

print info "Rolling old files example"

testfiles prepare
print step "Files before"
testfiles show

# default old files count = 9
file_prepare -r "$FILE_TEST"

print step "Files after"
testfiles show

testfiles delete
