#!/bin/bash
exit_func() {
rm -f "$temp_config"
}

timeout=10
retry=3
retrymaxtime=10
dir=sub
unset name git_path dir
OPTIND=1; while getopts :n:d:g: opt; do
	case "$opt" in	
        n) name=$OPTARG;;
        g) git_path=$OPTARG;;
        d) dir=$OPTARG;;
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;		
	esac
done; shift "$((OPTIND-1))"

if [ -z "$git_path" ] || [ -z "$name" ]; 
    echo "insufficient information"
    exit 1
fi

gitpull $git_path || { echo 'error: gitpull'; exit_func; exit 1; }

temp_config=$(mktemp)
clipboard -v > $temp_config

if head -n 1 "$temp_config" | grep -E -q '^http[s]?://'; then
    line=$(cat "$temp_config")
    curl -Lk --fail --silent --user-agent Mozilla --connect-timeout $timeout \
--retry $retry --retry-delay 0 --retry-max-time $retrymaxtime "${line}" > "$temp_config" 2>/dev/null || { echo "Error: curl" >&2;rm -f "$temp_config"; exit 1;} 
fi

mkdir -p "$git_path/$dir/$name"
cp -f "$temp_config" "$git_path/$dir/$name"

gitpush $git_path

echo "$link" | clipboard -c
mkqr -p
rm -f "$temp_config"