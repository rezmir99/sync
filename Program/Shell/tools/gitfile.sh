#!/bin/bash
. $HOME/lib/tools.lib.sh

file=$1
dir=$2

chk_net

[ -z "$GIT_PATH" ] && { echo "Error: no GIT_PATH specified" >&2; exit 1;}
pwd_old=$PWD
cd "$GIT_PATH" || exit
$PROXY_COMMAND -q git pull || exit

cd "$pwd_old"

mkdir -p "$GIT_PATH${dir:+/}${dir}"

cp -afr "$file" "$GIT_PATH${dir:+/}${dir}/${file##*/}"

cd "$GIT_PATH" || exit
$PROXY_COMMAND -q git add -- *
$PROXY_COMMAND -q git commit -m "Update via script"
$PROXY_COMMAND -q git push

