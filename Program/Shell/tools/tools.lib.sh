quoteSubst() { printf %s "$(printf '%s\n' "$1" | sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g')"; }

quoteRe() {
printf '%s' "$1" | sed -e 's/[^^]/[&]/g; s/\^/\\^/g'
}

chk_net() {
while [ "$SECONDS" -lt 10 ]; do
    $PROXY_COMMAND ping -q -c 1 soft98.ir >/dev/null 2>&1 && return 0
    sleep 1
done
return 1
}

is_changed() {
local md5_before md5_after
{ md5_before=$(<"$1.md5"); } 2>/dev/null
{ md5_after=$(md5sum "$1" | cut -d' ' -f 1); } 2>/dev/null
if [ "$md5_after" = "$md5_before" ]; then 
    return 1
else 
    printf '%s' "$md5_after" > "$1.md5"
    return 0
fi
}
