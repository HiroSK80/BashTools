#!/bin/bash

export TOOLS_FILE="$(dirname "$0")/tools.sh"
source "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

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
            #echo -e "    $FILE\\t$(cat $FILE)"
            #EOF
            file_loop "$FILE_TEST*" 'echo -e "    $FILE\t\t$(cat $FILE)\t$(stat -c %s "$FILE")b"'
        ;;
        delete)
            rm -f "$FILE_TEST"*
        ;;
    esac
}

print info "Rolling old files example"

testfiles prepare
print step "Files before prepare"
testfiles show

# roll file if is bigger than 1b
file_prepare --size 1 "$FILE_TEST"
# roll files, default old files count = 9
file_prepare --roll "$FILE_TEST"

print step "Files after prepare"
testfiles show

testfiles delete
