#!/bin/bash
. $HOME/lib/rawurl.lib.sh

today=$(date +"%Y-%m-%d")

unset link
# getopt
OPTIND=1; while getopts :scpl: opt; do
	case "$opt" in	
		s) singbox=true;;
		c) clear=true;;
		l) link="$OPTARG";;
		p) permanent=true;;
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;		
	esac
done; shift "$((OPTIND-1))"

if [ -z "$link" ]; then
	link=$(clipboard -v)
	echo "$link" | clipboard -c
fi

if [ "$clear" = true ]; then
	clear
fi

if [ "$singbox" = true ]; then
	tag=$(echo "$link" | grep -o '#.*$')
	[ -z "$tag" ] && tag="#$today"
	link=${link%%#*}
    link="sing-box://import-remote-profile?url=$(rawurlencode "$link")$tag"
fi

echo "\"$link\""
qrencode -m 2 -t utf8 <<< "$link"

if [ "$permanent" != true ]; then
	sleep 60
	clear
fi

exit 0
