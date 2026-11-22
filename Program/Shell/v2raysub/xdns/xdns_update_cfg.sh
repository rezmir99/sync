#!/bin/bash
. "$HOME/server_profile.sh"
bin_path="$PERM_GIT_PATH/Program/Linux/xdns"

config="config"
OPTIND=1; while getopts :c: opt; do
	case "$opt" in
        c) config="$OPTARG";;
        \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;
	esac
done; shift "$((OPTIND-1))"

sync_server

cp -f /root/xray-core/$config.json /root/xray-core/$config.json.bak
cp -f "$bin_path/$config.json" /root/xray-core/$config.json
systemctl restart xdns
