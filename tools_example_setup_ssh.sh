#!/bin/bash

export TOOLS_FILE="`dirname $0`/tools.sh"
. "$TOOLS_FILE" --debug "$@" || { echo "Error: Can't load \"$TOOLS_FILE\" file!" && exit 1; }

USER="$1"
HOST="$2"

test -z "$USER" -o -z "$HOST" && echo_error "Please specify user and host arguments"

echo_info "Configuring SSH access for current user to $USER@$HOST"
ssh_scanid $HOST
ssh_exportid $USER@$HOST
ssh_scanremoteid $USER@$HOST
ssh_importid $USER@$HOST
