#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug --debug-variable --debug-command "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

debug init_namespaces

USER="root"
HOST="10.50.135.104"
#HOST="hsot"

set_no PERFORMANCE_DETAILS
for FILE in "$USER@$HOST:/tmp/tools_test.cfg" #"/tmp/tools_test.cfg" "$USER@$HOST:/tmp/tools_test.cfg"
do
    echo_info "File destination URL parsing"
    echo_step "$FILE"
    declare -A URL
    str_parse_url "$FILE" URL
    echo_debug_variable URL
    echo_line

    echo_info "Testing file_line on file ${URL[FILE]}`test -n "${URL[HOST]}" && echo " on ${URL[USER]}@${URL[HOST]}"`"
    call_command --user="${URL[USER]}" --host="${URL[HOST]}" "uname -a; rm -f \"${URL[FILE]}\"; touch \"${URL[FILE]}\"; ls -l \"${URL[FILE]}\""
    performance start "" "Without remote file to local file cache"
    echo_step "adding lines: TEST1, TEST2"
    file_line add "$FILE" "TEST1"
    file_line add "$FILE" "TEST2"
    file_remote cat "$FILE"
    echo_step "modifying lines: .*1 to TESTx"
    file_line set "$FILE" "TESTx" "" ".*1"
    file_remote cat "$FILE"
    performance end
    file_delete "$FILE"
    echo_line

    file_remote cache init
    echo_info "Testing file_line on file ${URL[FILE]}`test -n "${URL[HOST]}" && echo " on ${URL[USER]}@${URL[HOST]}"`"
    call_command --user="${URL[USER]}" --host="${URL[HOST]}" "uname -a; rm -f \"${URL[FILE]}\"; touch \"${URL[FILE]}\"; ls -l \"${URL[FILE]}\""
    performance start "" "Cached remote file into local file"
    echo_step "adding lines: TEST1, TEST2"
    file_line add "$FILE" "TEST1"
    file_line add "$FILE" "TEST2"
    file_remote cat "$FILE"
    echo_step "modifying lines: .*1 to TESTx"
    file_line set "$FILE" "TESTx" "" ".*1"
    file_remote cat "$FILE"
    file_remote cache done
    performance stop
    file_delete "$FILE"
    echo_line
done


performance start "" "File delete local"
for I in {1..100}
do
    touch /root/simul_console/1
    file_delete_local /root/simul_console/1
done
performance end

performance start "" "File delete with URL test"
for I in {1..100}
do
    touch /root/simul_console/1
    file_delete /root/simul_console/1
done
performance end
