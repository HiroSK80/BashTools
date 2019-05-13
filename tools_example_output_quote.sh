#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

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
