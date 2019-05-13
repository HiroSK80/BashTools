#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

print info "Example pipe prefix function"
function sample_lines
{
    for X in 1 2 "3x \"3\" lines follows" 3 3 3 "2x empty lines follows" "" "" 4 5 6 "Here is long text\nseparated by two\nnew lines" "end"
    do
        echo -e "$X"
    done
}

sample_lines | pipe prefix --header="Input" --no-deduplicate --empty
# deduplicate and eliminate empty lines
sample_lines | pipe prefix --header="Output"
print

print info "Example for pipe join_lines function"
function sample_file
{
    cat << 'EOF'
test file
second line
file end
EOF
}

print step "Original file"
sample_file

print step "pipe join_lines"
sample_file | pipe join_lines

print step "pipe join_lines with none"
PIPE_JOIN_LINES_CHARACTER=""
sample_file | pipe join_lines

print step "pipe join_lines with \";\""
PIPE_JOIN_LINES_CHARACTER=";"
sample_file | pipe join_lines
