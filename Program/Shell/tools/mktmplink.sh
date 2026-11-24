#!/bin/bash

timeout=10
retry=3
retrymaxtime=10
tag=$(date "+%Y-%m-%d")

OPTIND=1; while getopts :t: opt; do
	case "$opt" in	
        t) tag="$OPTARG_$tag";;
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;		
	esac
done; shift "$((OPTIND-1))"

temp_config=$(mktemp)
clipboard -v > $temp_config

if head -n 1 "$temp_config" | grep -E -q '^http[s]?://'; then
    line=$(cat "$temp_config")
    curl -Lk --fail --silent --user-agent Mozilla --connect-timeout $timeout \
--retry $retry --retry-delay 0 --retry-max-time $retrymaxtime "${line}" > "$temp_config" 2>/dev/null || { echo "Error: curl" >&2;rm -f "$temp_config"; exit 1;} 
fi

link=$(curl -s https://bashupload.com -F=@"$temp_config" | grep -o 'https://.*$')
link="$link#$tag"
echo "$link" | clipboard -c
mkqr -p
rm -f "$temp_config"