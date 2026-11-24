#!/bin/bash
. "$HOME/server_profile.sh"

unset clean
OPTIND=1; while getopts :c opt; do
	case "$opt" in
        c) clean=true;;
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;		
	esac
done; shift "$((OPTIND-1))"

servicepath="/etc/systemd/system/$1.service"
servicename=$1
[ -s "$servicepath" ] || { echo "no service specified/defined"; exit 1; }
[ "$clean" = true ] && truncate -s 0 "$servicepath"

sudo nano "$servicepath"

sudo systemctl daemon-reload
sudo systemctl enable  $servicename.service
sudo systemctl restart $servicename.service