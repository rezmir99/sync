#!/bin/bash

unset uniq
OPTIND=1; while getopts :u opt; do
	case "$opt" in	
		u) uniq=-u;;
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;	
	esac
done; shift "$((OPTIND-1))"

clipboard -v | sed -e 's/[:]53//g' -e '/^ *$/d' -e 's/  *//g' | tr ',' '\n' | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -f -t '.' $uniq -k '1,3' | sort -u -V | clipboard -c

