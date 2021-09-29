#!/bin/bash

export TOOLS_FILE="$(dirname "$0")/tools.sh"
source "$TOOLS_FILE" "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

INPUT_FILE="$1"
test -z "$INPUT_FILE" && INPUT_FILE="tools_example_union.sh" && print warning "Input file not specified, unioning default file: $INPUT_FILE"

print info "Input file: $INPUT_FILE $(file_size_local "$INPUT_FILE")b"
print info "Tools file: $TOOLS_FILE $(file_size_local "$TOOLS_FILE")b"

tools_union "$INPUT_FILE"

print info "Unioned file: $UNION_FILE $(file_size_local "$UNION_FILE")b"
