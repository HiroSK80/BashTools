#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

declare -A PARSED

function show_parsed
{
    str_parse_url "$URL" PARSED
    test -n "${PARSED[USER]}${PARSED[HOST]}" && echo_substep "user@host: ${PARSED[USER]} @ ${PARSED[HOST]} via ${PARSED[PROTOCOL]}"
    test -n "${PARSED[FILE]}" && echo_substep "`test_yes "${PARSED[LOCAL]}" && echo "local" || echo "remote"` file: ${PARSED[FILE]}"
}

echo_info "URL parse test"

for URL in "scp://user@host:/path/file" "http://user@host/path/file" "ssh://user@host" "user@host:/path/file" "user@host:file" "host:/path/file" "/path/file" "file" "file:///etc/file:1" "/etc/sysconfig/network-scripts/ifcfg-eth1:1"
do
    echo_step "$URL"
    show_parsed
done

echo_info "URL parse test - alternative"
for URL in "host:file" "ifcfg-eth1:1"
do
    for PARSE_URL_PREFER_LOCAL in yes no
    do
        echo_step "$URL parsed as local $PARSE_URL_PREFER_LOCAL"
        show_parsed
    done
done
