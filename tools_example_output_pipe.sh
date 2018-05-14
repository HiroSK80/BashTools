#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

print info "Example echo_quote"

print "  input:      \"with space \\\"\$A\\\" var\" '{ print \"double inside\"; }' \"pa'd\" 'not_needed'"
print -e "  echo:       \c"
print "with space \"\$A\" var" '{ print "double inside"; }' "pa'd" 'not_needed'
print -e "  quoted:     \c"
print quote "with space \"\$A\" var" '{ print "double inside"; }' "pa'd" 'not_needed'
print
print "  input:      \"\\\"quoted with -\\\\\\\\\\\"- quotation mark\\\"\""
print -e "  echo:       \c"
print "\"quoted with -\\\"- quotation mark\""
print -e "  quoted:     \c"
print quote "\"quoted with -\\\"- quotation mark\""
print

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

cat > "$SCRIPT_FILE_NOEXT.txt" << 'EOF'
test file
second line
file end
EOF

print step "Original file"
cat "$SCRIPT_FILE_NOEXT.txt"

print step "pipe join_lines"
cat "$SCRIPT_FILE_NOEXT.txt" | pipe join_lines

print step "pipe join_lines with none"
PIPE_JOIN_LINES_CHARACTER=""
cat "$SCRIPT_FILE_NOEXT.txt" | pipe join_lines

print step "pipe join_lines with \";\""
PIPE_JOIN_LINES_CHARACTER=";"
cat "$SCRIPT_FILE_NOEXT.txt" | pipe join_lines
