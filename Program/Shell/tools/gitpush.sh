#!/bin/bash
. $HOME/lib/tools.lib.sh

GIT_PATH=$1
#chk_net || { echo "gitpush: Error: no internet" >&2; exit 1;}

[ -z "$GIT_PATH" ] && { echo "Error: no GIT_PATH specified" >&2; exit 1;}

cd "$GIT_PATH" || exit 1
$PROXY_COMMAND git pull || exit 1


$PROXY_COMMAND git add --all
$PROXY_COMMAND git commit -m "Update via script"
$PROXY_COMMAND git push || exit 1
exit 0

