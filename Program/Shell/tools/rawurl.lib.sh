# rawurl.lib.sh - percent-encode / decode (RFC 3986 unreserved set: -_.~ A-Z a-z 0-9)
#
# Usage:
#   rawurlencode STRING [VAR]
#   rawurldecode STRING [VAR]
#
#   * With VAR: result is stored in VAR, nothing is printed (no fork needed):
#         rawurldecode "$x" x
#   * Without VAR: result is printed AND set in REPLY (backward compatible):
#         y=$(rawurldecode "$x")
#
# Notes:
#   * Works byte-wise regardless of the caller's locale (LC_ALL=C is applied
#     locally), so UTF-8 text encodes to its UTF-8 bytes (é -> %c3%a9).
#   * Decoding is strict: only %HH with two hex digits is decoded. A stray '%'
#     ("100%", "%zz") and backslashes are kept literally. "%00" is dropped,
#     because bash variables cannot hold NUL.

rawurlencode() {
    local LC_ALL=C _ru_s=$1 _ru_out= _ru_safe _ru_c

    if [[ $_ru_s != *[!-_.~a-zA-Z0-9]* ]]; then
        _ru_out=$_ru_s                      # fast path: nothing to escape
    else
        while [[ -n $_ru_s ]]; do
            _ru_safe=${_ru_s%%[!-_.~a-zA-Z0-9]*}   # leading run of safe chars
            _ru_out+=$_ru_safe
            _ru_s=${_ru_s:${#_ru_safe}}
            [[ -n $_ru_s ]] || break
            printf -v _ru_c '%%%02x' "'${_ru_s:0:1}"
            _ru_out+=$_ru_c
            _ru_s=${_ru_s:1}
        done
    fi

    if [[ -n $2 ]]; then printf -v "$2" '%s' "$_ru_out"
    else REPLY=$_ru_out; printf '%s' "$_ru_out"
    fi
}

rawurldecode() {
    local LC_ALL=C _ru_s=$1 _ru_out= _ru_t _ru_h _ru_c _ru_seg

    if [[ $_ru_s != *%* ]]; then
        _ru_out=$_ru_s                      # fast path: nothing to decode
    else
        _ru_t=${_ru_s//%[0-9a-fA-F][0-9a-fA-F]/}
        if [[ $_ru_t != *%* ]]; then
            # every '%' starts a valid %HH: decode in one shot
            _ru_s=${_ru_s//%00/}            # NUL cannot be stored
            _ru_s=${_ru_s//\\/\\\\}         # keep literal backslashes
            printf -v _ru_out '%b' "${_ru_s//%/\\x}"
        else
            # stray '%' present: walk through it, decode only valid %HH
            _ru_out=${_ru_s%%\%*}
            _ru_s=${_ru_s#"$_ru_out"}
            while [[ $_ru_s == %* ]]; do
                _ru_h=${_ru_s:1:2}
                if [[ $_ru_h == [0-9a-fA-F][0-9a-fA-F] ]]; then
                    [[ $_ru_h == 00 ]] || { printf -v _ru_c "\\x$_ru_h"; _ru_out+=$_ru_c; }
                    _ru_s=${_ru_s:3}
                else
                    _ru_out+='%'
                    _ru_s=${_ru_s:1}
                fi
                _ru_seg=${_ru_s%%\%*}
                _ru_out+=$_ru_seg
                _ru_s=${_ru_s#"$_ru_seg"}
            done
        fi
    fi

    if [[ -n $2 ]]; then printf -v "$2" '%s' "$_ru_out"
    else REPLY=$_ru_out; printf '%s' "$_ru_out"
    fi
}

# support functions for protecting IFS stack
declare -a _IFS_STACK=()

setifs() {
    IFS=${1-$' \t\n'}
}

pushifs() {
    _IFS_STACK+=("$IFS")                    # push the current IFS
    [ $# -gt 0 ] && IFS=$1                  # set IFS from argument (if any)
}

popifs() {
    local n=${#_IFS_STACK[@]}
    (( n > 0 )) || return 1                 # stack empty
    IFS=${_IFS_STACK[n-1]}
    unset '_IFS_STACK[n-1]'
}
