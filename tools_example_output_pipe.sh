#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

echo_info "Example echo_quote"

echo_line "  input:      \"with space \\\"\$A\\\" var\" '{ print \"double inside\"; }' \"pa'd\" 'not_needed'"
echo_line -e "  echo:       \c"
echo_line "with space \"\$A\" var" '{ print "double inside"; }' "pa'd" 'not_needed'
echo_line -e "  echo_quote: \c"
echo_quote "with space \"\$A\" var" '{ print "double inside"; }' "pa'd" 'not_needed'
echo_line
echo_line "  input:      \"\\\"quoted with -\\\\\\\\\\\"- quotation mark\\\"\""
echo_line -e "  echo:       \c"
echo_line "\"quoted with -\\\"- quotation mark\""
echo_line -e "  echo_quote: \c"
echo_quote "\"quoted with -\\\"- quotation mark\""
echo_line

echo_info "Example pipe_prefix function"

function sample_lines
{
    for X in 1 2 "3x \"3\" lines" 3 3 3 "2x empty lines" "" "" 4 5 6 "Here is long text\nseparated by two\nnew lines" "7" "end"
    do
        echo -e "$X"
    done
}

# deduplicate and eliminate empty lines
sample_lines | pipe_prefix
echo_line

echo_info "Example for pipe_join_lines function"

cat > "$SCRIPT_FILE_NOEXT.txt" << 'EOF'
test file
second line
file end
EOF

echo_step "Original file"
cat "$SCRIPT_FILE_NOEXT.txt"

echo_step "pipe_join_lines"
cat "$SCRIPT_FILE_NOEXT.txt" | pipe_join_lines

echo_step "pipe_join_lines with none"
PIPE_JOIN_LINES_CHARACTER=""
cat "$SCRIPT_FILE_NOEXT.txt" | pipe_join_lines

echo_step "pipe_join_lines with \";\""
PIPE_JOIN_LINES_CHARACTER=";"
cat "$SCRIPT_FILE_NOEXT.txt" | pipe_join_lines
