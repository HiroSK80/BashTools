#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

cat > "$SCRIPT_FILE_NOEXT.txt" << 'EOF'
#test file
#START
#REPL1, REPL2
#END
#file end
EOF

echo_info "Original file"
cat "$SCRIPT_FILE_NOEXT.txt"

echo_info "Generated file"
# == cat "$SCRIPT_FILE_NOEXT.txt" | pipe_replace START END REPL1,REPL2 "repl1a,repl2a;repl1b,repl2b"
file_replace "$SCRIPT_FILE_NOEXT.txt" START END REPL1,REPL2 "repl1a,repl2a;repl1b,repl2b"
cat "$SCRIPT_FILE_NOEXT.txt"
