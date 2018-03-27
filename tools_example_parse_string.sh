#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-function --debug-right "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

declare -A PARSED PARSED_LOCAL PARSED_SMART PARSED_REMOTE

function show_parsed
{
    array_copy "$1" PARSED
    test -n "${PARSED[USER]}${PARSED[PASSWORD]}${PARSED[HOST]}" && echo_substep "${PARSED[USER]:-<empty>} : ${PARSED[PASSWORD]:-<empty>} @ ${PARSED[HOST]:-<empty>} : ${PARSED[PORT]:-<empty>} via ${PARSED[PROTOCOL]:-<empty>}          ${PARSED[USER_HOST]}"
    test -n "${PARSED[FILE]}" && echo_substep "`test_yes "${PARSED[LOCAL]}" && echo "local" || echo "remote"`: ${PARSED[FILE]}"
}

echo_info "URL parse test"
for URL in \
    "scp://host:file" \
    "scp://host:1234:file" \
    "scp://host:/path/file" \
    "scp://host:1234/path/file" \
    "scp://user@host:/path/file" \
    "scp://user@host:1234:/path/file" \
    "scp://user:password@host:/path/file" \
    "scp://user:password@host:1234:/path/file" \
    "http://www.host" \
    "http://www.host:1234" \
    "http://www.host/path/file" \
    "http://user@host/path/file" \
    "http://user@host:1234/path/file" \
    "http://user:password@host/path/file" \
    "http://user:password@host:1234/path/file" \
    "https://email%40gmail.com:password@www.site.com/login" \
    "https://email%40gmail.com:password@www.site.com:1234/login" \
    "ssh://user@host" \
    "ssh://user@host:1234" \
    "ssh://user:password@host" \
    "ssh://user:password@host:1234" \
    "host:file" \
    "host:1234:file" \
    "host:/path/file" \
    "host:1234/path/file" \
    "user@host" \
    "user@host:" \
    "user:password@host" \
    "user@host:file" \
    "user@host:/path/file" \
    "user:password@host:file" \
    "user:password@host:/path/file" \
    "user:password@host/file" \
    "user:password@host/path/file" \
    "host/path/file" \
    "/path/file" \
    "file" \
    "path/file" \
    "file:///etc/file:1" \
    "file://nouser@nohost/etc/file:1" \
    "/etc/sysconfig/network-scripts/ifcfg-eth1:1"
do
    PARSE_URL_DETECT="local"
    str_parse_url "$URL" PARSED_LOCAL
    array_copy PARSED_LOCAL PARSED
    TEST_L="${PARSED[PROTOCOL]}|${PARSED[USER]}|${PARSED[PASSWORD]}|${PARSED[HOST]}|${PARSED[PORT]}|${PARSED[FILE]}"

    PARSE_URL_DETECT="smart"
    str_parse_url "$URL" PARSED_SMART
    array_copy PARSED_SMART PARSED
    TEST_S="${PARSED[PROTOCOL]}|${PARSED[USER]}|${PARSED[PASSWORD]}|${PARSED[HOST]}|${PARSED[PORT]}|${PARSED[FILE]}"

    PARSE_URL_DETECT="remote"
    str_parse_url "$URL" PARSED_REMOTE
    array_copy PARSED_REMOTE PARSED
    TEST_R="${PARSED[PROTOCOL]}|${PARSED[USER]}|${PARSED[PASSWORD]}|${PARSED[HOST]}|${PARSED[PORT]}|${PARSED[FILE]}"

    echo_line "${COLOR_GREEN}== $URL${COLOR_RESET}"
    if test "$TEST_L" = "$TEST_R" -a "$TEST_S" = "$TEST_R"
    then
        echo_step "local/smart/remote"
        show_parsed PARSED_LOCAL
    elif test "$TEST_L" = "$TEST_S" -a "$TEST_S" != "$TEST_R"
    then
        echo_step "local/smart"
        show_parsed PARSED_LOCAL
        echo_step "remote"
        show_parsed PARSED_REMOTE
    elif test "$TEST_L" != "$TEST_S" -a "$TEST_S" = "$TEST_R"
    then
        echo_step "local"
        show_parsed PARSED_LOCAL
        echo_step "smart/remote"
        show_parsed PARSED_REMOTE
    else
        echo_step "local"
        show_parsed PARSED_LOCAL
        echo_step "smart"
        show_parsed PARSED_SMART
        echo_step "remote"
        show_parsed PARSED_REMOTE
    fi
done

echo_info "URL parse test - conflicts"
for URL in "host/path/file" "host:file" "ifcfg-eth1:1"
do
    for PARSE_URL_DETECT in local smart remote
    do
        echo_line "${COLOR_GREEN}== $URL${COLOR_RESET} parsed as ${COLOR_WHITE}$PARSE_URL_DETECT${COLOR_RESET}"
        str_parse_url "$URL" PARSED
        show_parsed PARSED
    done
done
