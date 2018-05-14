#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

function file
{
    case "$1" in
        create)
            cat > "$SCRIPT_FILE_NOEXT.txt" << 'EOF'
test file
REPL_START
first line with REPL1 and REPL2 replaces
second line REPL1 with one replace
REPL_END
file end
EOF
            ;;
        show)
            pipe prefix --file="$SCRIPT_FILE_NOEXT.txt"
            ;;
    esac
}

print info "Original file"
file create
file show

print info "Generated file with simple one pattern replace"
file_replace "$SCRIPT_FILE_NOEXT.txt" "REPL[12]" "repl"
file show

print info "Generated file with complex several patterns replace"
# == cat "$SCRIPT_FILE_NOEXT.txt" | pipe replace REPL_START REPL_END REPL1,REPL2 "repl1a,repl2a;repl1b,repl2b"
file create
file_replace "$SCRIPT_FILE_NOEXT.txt" REPL_START REPL_END REPL1,REPL2 "repl1a,repl2a;repl1b,repl2b"
file show

file create
