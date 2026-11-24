ui_printf() {
if [ "$OUTFD" ]; then
	printf "$@" | while IFS= read -r line; do
		printf 'ui_print %s\nui_print\n' "$line" 
	done >>/proc/self/fd/$OUTFD
else
	printf "$@"
fi
}

install_busybox() {
local source destination 
if [ $# -eq 2 ]; then
	if [ -d "$1" ]; then source="$1/busybox"; else source="$1"; fi
	destination="$2"
elif [ $# -eq 1 ]; then
	destination="$1"
else ui_printf 'Error: Needs "[source] destination" argument\n' 1>&2; return 1 
fi

[ -e "$destination" ] && [ ! -d "$destination" ] && { ui_printf "Error: %s isnt a directory" "$destination\n" 1>&2; return 1; }
test -z "$MAGISKBIN" && MAGISKBIN="/data/adb/magisk"

if [ -z "${source+z}" ]; then
	if [ -x $MAGISKBIN/busybox ]; then
		source=$MAGISKBIN/busybox
	elif [ -x /system/xbin/busybox ]; then
		source=/system/xbin/busybox
	elif [ -x "$(command -v busybox 2>/dev/null)" ]; then
		source=$(command -v busybox 2>/dev/null)
	fi
fi
[ ! -x "$source" ] && { ui_printf 'Error: cant execute busybox binary\n' 1>&2; return 1; }
	
if [ ! -f "$destination/busybox" ]; then
	mkdir -p "$destination" || { ui_printf 'Error: cant create $destination\n' 1>&2; return 1; }
	chown 0:0 "$destination"
	chmod 0755 "$destination"
	#"$source" ln -sf "$source" "$destination/busybox"
	#"$source" --install -s "$destination"
	for i in $("$source" --list); do
		"$source" ln -sf "$source" "$destination/$i" || { ui_printf 'Error: cant create applets in $destination\n' 1>&2; return 1; }
	done
fi
}

uniq_path() (
set -f; newpath=; rm=;
[ "$1" = "-r" ] && { rm=$2; shift 2; }
IFS=':'
for dir in ${1}; do
	case ":$newpath:" in 
	(*":$dir:"*) true;; 
	(*) case ":$rm:" in (*":$dir:"*) true;; (*) [ -d "$dir" ] && newpath="${newpath}${newpath:+:}${dir}";; esac;;
	esac
done
echo "${newpath}"
)

mktouch() {
mkdir -p "${1%/*}" 2>/dev/null || return $?
if [ ! -f "$1" ]; then touch "$1" || return $?; fi
if [ -n "${2+z}" ]; then { chmod 644 "$1"; echo "$2" > "$1"; touch "$1"; } || return $?; fi
}

cp_ch() {
if [ -e "$1" ]; then
	mkdir -p "${2%/*}"
	chmod 0755 "${2%/*}"
	cp -af "$1" "$2"
	if [ -z "$3" ]; then 
		[ ! -z "${1##\/system\/*}" ] && chmod 0644 "$2"
	else
		chmod "$3" "$2"
	fi
fi
}

tweak_prop() {
local redirect arg backup file prop entry var restore unique opt
restore=false
unique=false

OPTIND=1; while getopts :b:f:p:ruh opt; do
	case "$opt" in
		b) backup=$OPTARG;;
		f) file=$OPTARG;;
		p) prop=$OPTARG;;
		r) restore=true;;
		u) unique=true;;
	    h) show_help; return;;	   
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; return 1;;
		*) show_help; return 1;;		
	esac
done; shift "$((OPTIND-1))"

if [ $# -gt 1 ]; then 
	ui_printf "Only one property can be specified" 1>&2
	return 1
elif [ $# -eq 1 ] && [ "$file" ]; then
	ui_printf "Only one of property or file can be specified" 1>&2
	return 1
elif [ -n "${file+z}" ]; then
	if [ -s "$file" ]; then 
		redirect="cat";
	elif [ ! -f "$file" ]; then { ui_printf "$file : no such a file" 1>&2; return; }
	fi
elif [ -n "${1+z}" ]; then
	if [ "$(echo "$1" | grep -c '^[^ =]*=[^ =]*$')" -eq 1 ]; then 
		redirect="echo"; file=$1; 
	else 
		{ ui_printf "Illegal property format" 1>&2; return; }; 
	fi
fi

test -d "$prop" && prop="$prop/build.prop"
test -d "$backup" && backup="${backup}/build.prop"

test -z "$prop" && prop="/system/build.prop"
test -z "$backup" && backup="${prop}.bak"

test "$prop" = "$file" && { ui_printf "invalid tweak file" 1>&2; return 1; }
test "$prop" = "$backup" && backup="${prop}.bak"

if [ ! -f "$backup" ]; then
    test ! -f "$prop" -o "$restore" = "true" && { ui_printf "invalid prop or backup file" 1>&2; return 1; }
	mkdir -p ${backup%/*} || return
	cp -af "$prop" "$backup" || return
elif [ "$restore" = "true" -o ! -f "$prop" ]; then
	cp -af "$backup" "$prop" || return
	chmod 0644 "${prop}"
fi

[ -s "${prop}" ] && { tail -n1 "${prop}" | read -r _l || printf '\n' >> "${prop}"; }

cp -af "$prop" "${prop}.tmp"

if $unique; then
sed 's/^[\t ]*//; s/[\t ]*$//; /^[\t ]*$/d' "$prop" | nl -b a -s'=' | sed -e 's/^[\t ]*[0-9][0-9]*=#/=&/' | sort -ru -k 2,2 -t= | sed -e 's/^=//' | sort -nk1 -t= | cut -d= -f 2- > "${prop}.tmp"
fi

if [ "$redirect" ]; then
if ! grep -q "^###### TWEAK.PROP" "${prop}.tmp" || ! grep -q "^######    END" "${prop}.tmp"; then
	sed -i -e 's/^###### TWEAK.PROP/#/g' -e 's/^######    END/#/g' "${prop}.tmp"; 
	printf '%s\n%s\n' "###### TWEAK.PROP ######" "######    END     ######" >> "${prop}.tmp"; 
fi
## read only lines matching valid entry pattern (someVAR=someVAL, !someSTR, @someENTR|someSTR, $someVAR=someVAL)
$redirect "$file" | sed '$a\' | sed -r '/(^[\t ]*#|^[\t ]*$)/d;/(.*=.*|^\!|^\&.*=.*)/!d' | sed 's/^[\t ]*//; s/[\t ]*$//; /^[\t ]*$/d' | nl -b a -s'=' | sort -ru -k 2,2 -t= | sort -nk1 -t= | cut -d= -f 2- | while read -r line
do
	## remove entry only if entry exists
	if echo "$line" | grep -q '^\!'
	then
		entry="$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')"
		sed -i -e "/$entry/d" "${prop}.tmp"
	
	elif echo "$line" | grep -q '^\&'
	then
		entry="$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')"
		var="$(echo "$entry" | cut -d= -f1)"
		## change $var's value if $var present in $prop
		if grep -q "^$var=" "${prop}.tmp"; then 
			sed -i -e "s/^${var}=.*/${entry}/" "${prop}.tmp"
		fi
	## add or override entry
	else
		entry="$(echo "${line}" | sed -e 's/[\/&]/\\&/g')"
		var="$(echo "$line" | cut -d= -f1)"
		if grep -q "^$var=" "${prop}.tmp"; then
        sed -i -e "s/^${var}=.*/${entry}/" "${prop}.tmp"
		else
		sed -i -e "s/^######    END/${entry}\\n&/" "${prop}.tmp"
		fi
	fi
done
 fi
mv -f "${prop}.tmp" "$prop"
chmod 0644 "${prop}"
}

retouch() {
mkdir -p "${1%/*}" 2>/dev/null || return $?
touch -m "$1" || return $?
chmod 644 "$1"
if [ -z "${2+z}" ]; then truncate -s 0 "$1" || return $?; else echo "$2" > "$1" || return $?; fi
}

quoteRe() {
printf '%s\n' "$1" | sed -e 's/[^^]/[&]/g; s/\^/\\^/g; $!a\
\\n' | tr -d '\n';
}

quoteSubst() { printf %s "$(printf '%s\n' "$1" | sed -e ':a' -e '$!{N;ba' -e '}' -e 's/[&/\]/\\&/g; s/\n/\\&/g')"; }

esc() { printf '%s\n' "$1" | sed "s/'/'\\\\''/g; 1 s/^/'/; \$ s/\$/'/"; }

match() {
local p='*'
[ "$1" = "-p" ] && { shift; p=; }
eval "case \"\$1\" in ($p${p:+\"}\$2${p:+\"}$p) return 0;; (*) return 1;; esac"
}

set_var() {
if [ -n "$(sed -n "/^${1}=/p" "$3")" ]; then
	sed -i "s/^${1}=.*/${1}=$(quoteSubst "$(esc "$2")")/" "$3"
else
	sed -i "s/\\\$${1}/$(quoteSubst "$2")/g" "$3"
fi
}

set_variables() {
local X
for FILE in "$@"; do
	eval "X=\$${FILE}"
	eval "set -A ${FILE}"
	while read -r line; do 
		eval "${FILE}+=(${line#*=})"
		test "${line/*=*/true}" = "true" && eval export "${line}"
	done <<<"$X"
done
}

getin() {
local _n_='\n' _prompt_=false
while [ $# -gt 0 ]; do case "$1" in
   -n) _n_=' ';;
   -p) _prompt_=true; _n_='(Y/N) ';;
   --) shift; break;;
    *) break;;
esac; shift; done

if $_prompt_; then
	while true; do
		printf "%s$_n_" "$1"
		read answer
			case $answer in 
			  [yY]|[Yy][Ee][sS]) return 0;;
			  [nN]|[nN][oO]) return 1;;
			  *) printf "Invalid answer\n"; continue;;
			esac
	done
else
	printf "%s$_n_" "$1"
	read -r answer
	[ "$2" ] && eval $2=\$answer
fi
}

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

repeat() {
local arg i number delay clear opt
number=100
delay=5
clear=100
OPTIND=1; while getopts :n:d:c:h opt; do
	case "$opt" in
		n) number=$OPTARG;;
		d) delay=$OPTARG;;
		c) clear=$OPTARG;;
	    h) show_help; return;;	   
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; return 1;;
		*) show_help; return 1;;		
	esac
done
shift "$((OPTIND-1))"

test "$#" -lt "1" && { echo "no command to repeat"; return; }

[ -z "${number##*[!0-9]*}" ] && { printf 'Error: bad number number\n' 1>&2; return 1; }
[ -z "${delay##*[!0-9]*}" ] && { printf 'Error: bad delay number\n' 1>&2; return 1; }
[ -z "${clear##*[!0-9]*}" ] && { printf 'Error: bad clear number\n' 1>&2; return 1; }

clear
i=1
while [ "$i" -le "$number" ]; do
	[ "$(( i % clear ))" -eq 0 ] && clear
    "$@"
	[ "$i" -eq "$number" ] || sleep "$delay"
	i=$((i+1))
done
}

findopt() {
local ARG OPTARG recheck=false short long arg; #set -x
while [ $# -gt 0 ]; do case "$1" in
   -s|--short) short=$(echo $2 | sed 's/./-& /g'); shift 2;;
   -l|--long) long=$(echo $2 | sed 's/,/ /g; s/[^ ][^ ]*/--&=/g'); shift 2;;
    *) [ "$1" = "--" ] && shift; break;;
esac; done
while [ $# -gt 0 ]; do
	if $recheck; then recheck=false; arg="${arg#-}"; arg="-${arg#?}"; case "$arg" in
		(--*) OPTARG="$OPTARG $(printf "'-- -'\\n")"; recheck=true; continue;;
		(-?*) true;;
		(*) shift; continue;; esac
	else arg="$1"; fi
	for opt in $short $long; do case "$arg" in
			(${opt}?*) OPTARG="$OPTARG${OPTARG:+ }${opt%=} $(eval esc \"\${arg#$opt}\")"; shift; continue 2;;
			(${opt%=}) if [ $# -ge 2 ] && [ "$2" != '--' ]; then OPTARG="$OPTARG${OPTARG:+ }${opt%=} $(esc "$2")"; shift 2; else OPTARG="$OPTARG${OPTARG:+ }: ${opt%=}"; shift; fi; continue 2;;
			(${opt%=}=) [ -z "${opt##--*=}" ] && { OPTARG="$OPTARG${OPTARG:+ }: ${opt%=}"; shift; continue 2; };;
    esac; done
	case "$arg" in
	   --) OPTARG="$OPTARG${OPTARG:+ }--"; shift; for arg; do ARG="$ARG${ARG:+ }$(esc "${arg}")"; done; arg=; break;;
	  --*) OPTARG="$OPTARG${OPTARG:+ }${arg}"; shift;;
	   -*) OPTARG="$OPTARG${OPTARG:+ }$(printf "'%.2s'" "${arg}")"; recheck=true;;
		*) ARG="$ARG${ARG:+ }$(esc "${arg}")"; shift;;
	esac; 
done; printf '%s\n' "$OPTARG$([ "$OPTARG" ] && [ "$ARG" ] && printf ' ')$ARG"
}

run() {
cp -f "$1" "/data/${1##*/}" || return
chmod 0755 "/data/${1##*/}"
local path="$1"
shift
sh "/data/${path##*/}" "$@"
test -n "${path##*/}" && rm -f "/data/${path##*/}"
}

diff_val() {
local time_diff hrs min dt sec update arg time_1 time_2 diff_file ref_file now opt
update=false

arg=; [ $# -gt 0 ] && opt="$1"; while [ $# -gt 0 ]; do
	case "$opt" in
	  -[uU]*|--update) update=true;;	   
		   -h*|--help) show_help; return;;
				   --) shift; for opt; do arg="$arg $(esc "$opt")"; done; break;;
		          --*) printf 'Error: Unknown option "%s"\n' "$opt" 1>&2; return 1;;		   
				   -*) printf 'Error: Unknown option "-%.2s"\n' "$opt" 1>&2; return 1;;
					*) arg="$arg $(esc "$opt")";;						
	esac
	case "$opt" in (-[!-]-*) opt="-- -";; (-[!-]?*) opt="-${opt#-?}";; (*) shift; [ $# -gt 0 ] && opt="$1";; esac
done; [ "$arg" ] && eval set -- "$arg"; opt=; arg=;

[ "$#" -gt 2 ] && { echo "only two files can be specified" 1>&2; return 1; }
[ ! -f "$1" ] && { echo "$1: no file to compare" 1>&2; return 1; }

ref_file=$2
[ -z "$ref_file" ] && if mktouch "${1%/*}/ref.${1##*/}" >/dev/null 2>&1; then
                         ref_file="${1%/*}/ref.${1##*/}"; 
	                  elif mktouch "$TMPDIR/ref.${1##*/}" >/dev/null 2>&1; then
					     ref_file="$TMPDIR/ref.${1##*/}";
                      else echo "cant access reference file" 1>&2; return 1;
					  fi

diff_file="${ref_file%/*}/val.${ref_file##*/}"

if [ -s "$ref_file" ]; then
	retouch "$diff_file" || { echo "cant create diff file $diff_file" 1>&2; return 1; }
	
	awk 'NR==FNR{for (i=1; i<=NF; ++i) {if ($i~/[0-9]+/) a[FNR,i]=$i};next} NR!=FNR{for (i=1; i<=NF; ++i) {if ($i~/[0-9]+/) {diff = $i - a[FNR,i];printf "%d ", diff} else {printf "%s ", $i}};printf "\n"}' "$ref_file" "$1" >> "$diff_file" || return $?
	
	time_2=$(date -r "$1" +%s); time_1=$(date -r "$ref_file" +%s);
	time_diff=$((time_2 - time_1))
	((sec=time_diff%60, time_diff/=60, min=time_diff%60, hrs=time_diff/60, dt=time_diff/1440))
	sed -i "1s/.*/$(date -r "$1") - Difference in $(printf "%d days:%02d:%02d:%02d" "$dt" "$hrs" "$min" "$sec")\\n--- ${1//\//\\\/}\\n+++ ${ref_file//\//\\\/}\\n/" "$diff_file"
	if $update; then cp -af "$1" "$ref_file" >/dev/null 2>&1 || { echo "cant create reference file" 1>&2; return 1; }; fi
	cat "$diff_file"
else
	printf 'No Reference Data\n'
	cp -af "$1" "$ref_file" >/dev/null 2>&1 || { echo "cant create reference file" 1>&2; return 1; }
fi
}

diff_txt() {
local time_diff hrs min dt sec update arg time_1 time_2 diff_file ref_file now opt
update=false
arg=; [ $# -gt 0 ] && opt="$1"; while [ $# -gt 0 ]; do
	case "$opt" in
	  -[uU]*|--update) update=true;;	   
		   -h*|--help) show_help; return;;
				   --) shift; for opt; do arg="$arg $(esc "$opt")"; done; break;;
		          --*) printf 'Error: Unknown option "%s"\n' "$opt" 1>&2; return 1;;		   
				   -*) printf 'Error: Unknown option "-%.2s"\n' "$opt" 1>&2; return 1;;
					*) arg="$arg $(esc "$opt")";;						
	esac
	case "$opt" in (-[!-]-*) opt="-- -";; (-[!-]?*) opt="-${opt#-?}";; (*) shift; [ $# -gt 0 ] && opt="$1";; esac
done; [ "$arg" ] && eval set -- "$arg"; opt=; arg=;

[ "$#" -gt 2 ] && { echo "only two files can be specified" 1>&2; return 1; }
[ ! -f "$1" ] && { echo "$1: no file to compare" 1>&2; return 1; }

ref_file=$2
[ -z "$ref_file" ] && if mktouch "${1%/*}/ref.${1##*/}" >/dev/null 2>&1; then
                         ref_file="${1%/*}/ref.${1##*/}"; 
	                  elif mktouch "$TMPDIR/ref.${1##*/}" >/dev/null 2>&1; then
					     ref_file="$TMPDIR/ref.${1##*/}";
                      else echo "cant access reference file" 1>&2; return 1;
					  fi

diff_file="${ref_file%/*}/txt.${ref_file##*/}"

if [ -s "$ref_file" ]; then
	retouch "$diff_file" || { echo "cant create diff file $diff_file" 1>&2; return 1; }
	
	diff -U "$(wc -l < "$1")" "$1" "$ref_file" | sed -n -e 's/^-//p' -e '1d' >> "$diff_file"
	time_2=$(date -r "$1" +%s); time_1=$(date -r "$ref_file" +%s);
	time_diff=$((time_2 - time_1))
	((sec=time_diff%60, time_diff/=60, min=time_diff%60, hrs=time_diff/60, dt=time_diff/1440))
    sed -i "1s/.*/$(date -r "$1") - Difference in $(printf "%d days:%02d:%02d:%02d" "$dt" "$hrs" "$min" "$sec")\\n--- ${1//\//\\\/}\\n+++ ${ref_file//\//\\\/}\\n/" "$diff_file"
	if $update; then cp -af "$1" "$ref_file" >/dev/null 2>&1 || { echo "cant create reference file" 1>&2; return 1; }; fi
	cat "$diff_file"
else
	printf 'No Reference Data\n'
    cp -af "$1" "$ref_file" >/dev/null 2>&1 || { echo "cant create reference file" 1>&2; return 1; }
fi
}

cvt() {
local date_format uptime now file cputime input
date_format="%a %b %d %Y %T %Z"
#cputime=$(grep -m1 "\.clock" /proc/sched_debug | sed -n -e 's/^[^0-9]*\([0-9]*\).*/\1/p')
uptime=$(cut -d " " -f 1 /proc/uptime | cut -d '.' -f 1)
now=$(date +%s)
GMT=0

if [ $# -gt 1 ]; then { echo "only one file can be specified" 1>&2; return 1; }
elif [ $# -eq 1 ]; then 
	if [ -f "$1" ]; then input=$1; else { echo "$1 : no such a file" 1>&2; return 1; }; fi
fi
if [ -n "${input+z}" ]; then cat "$input"; else cat; fi | sed -e 's/^[^[]/b &/' -e 's/^\[[ ]*\([0-9]*\)[0-9.]*\] \(.*\)/\1 \2/' | while read -r timestamp message; do
	[[ "$timestamp" = *([0-9]) ]] && printf "[%s] %s\n" "$(date --date @$((now - uptime + timestamp + GMT)) +"${date_format}")" "$message" || printf "%s\n" "$message"
done
}

memavailable() {
if grep -q "MemAvailable" "/proc/meminfo"; then
	MEMAVAILABLE_KB=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
else
	LOW_WATERMARK=$(awk '$1 == "low" {LOW_WATERMARK += $2} END {print LOW_WATERMARK * 4096}' /proc/zoneinfo)

	MEMINFO=$(</proc/meminfo)

	MEMINFO_MEMFREE=$(echo "${MEMINFO}" | awk '$1 == "MemFree:" {print $2 * 1024}')
	MEMINFO_FILE=$(echo "${MEMINFO}" | awk '{MEMINFO[$1]=$2} END {print (MEMINFO["Active(file):"] + MEMINFO["Inactive(file):"]) * 1024}')
	MEMINFO_SRECLAIMABLE=$(echo "${MEMINFO}" | awk '$1 == "SReclaimable:" {print $2 * 1024}')

	MEMAVAILABLE=$((
	  MEMINFO_MEMFREE - LOW_WATERMARK
	  + MEMINFO_FILE - ((MEMINFO_FILE/2) < LOW_WATERMARK ? (MEMINFO_FILE/2) : LOW_WATERMARK)
	  + MEMINFO_SRECLAIMABLE - ((MEMINFO_SRECLAIMABLE/2) < LOW_WATERMARK ? (MEMINFO_SRECLAIMABLE/2) : LOW_WATERMARK)
	))

	if [ "${MEMAVAILABLE}" -le 0 ]; then
	  MEMAVAILABLE=0
	fi
	
	MEMAVAILABLE_KB=$(( MEMAVAILABLE / 1024 ))
fi

echo " MemAvailable: ${MEMAVAILABLE_KB} KB"
#echo " Reserved momory: $(( $LOW_WATERMARK / 1024 )) KB"
}

disk_test() {
local arg i number size writes reads buffers sp write_average read_average buffer_average var opt
verbose=false
size=400
number=3
OPTIND=1; while getopts :n:s:vh opt; do
	case "$opt" in
		n) number=$OPTARG;;
		s) size=$OPTARG;;
		v) verbose=true;;
	    h) show_help; return;;	   
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; return 1;;
		*) show_help; return 1;;		
	esac
done; shift "$((OPTIND-1))"

[ -z "${number##*[!0-9]*}" ] && { 'Error: bad count number\n' 1>&2; return 1; }
[ -z "${size##*[!0-9]*}" ] && { 'Error: bad size number\n' 1>&2; return 1; }
test "$#" -lt "1" && { echo "no disk to test"; return; }


filepath=$1

if [ -d "$filepath" ]; then
	filepath="$filepath/tempfile"
else 
	mkdir -p "${filepath%/*}" || return 1
fi
freemb=$(df -P "${filepath%/*}" | awk 'NR==2 {print $4}')

if [ "$freemb" -lt "$((size * 1024))" ]; then
	echo "do not have $size MB space for disk test"
	return 1
fi

i=1
while [ "$i" -le "$number" ]; do
	# write a test file to measure write speeds and to give the device something to read:
	write=$(dd if=/dev/zero of="$filepath" bs=1M count=$size conv=fsync,notrunc 2>&1 || echo "error $?")
	$verbose && echo "$write"
	[[ "$write" = *error* ]] && { echo "$write"; return 1; }
	write=${write##*,*([!0-9])}; if [[ "$write" = *GB* ]]; then writes+=($((${write%%+([!0-9])*} * 1024 * 1024))); elif [[ "$write" = *MB* ]]; then writes+=($((${write%%+([!0-9])*} * 1024))); else writes+=(${write%%+([!0-9])*}); fi
	sleep 0.1
	
	# Next, clear the buffer-cache to accurately measure read speeds directly from the device:
	echo 3 > /proc/sys/vm/drop_caches
	read=$(dd if="$filepath" of=/dev/null bs=1M count=$size 2>&1 || echo "error $?")
	$verbose && echo "$read"
	[[ "$read" = *error* ]] && { echo "$read"; return 1; }
	read=${read##*,*([!0-9])}; if [[ "$read" = *GB* ]]; then reads+=($((${read%%+([!0-9])*} * 1024 * 1024))); elif [[ "$read" = *MB* ]]; then reads+=($((${read%%+([!0-9])*} * 1024))); else reads+=(${read%%+([!0-9])*}); fi
	sleep 0.1
	
	#Now that the last file is in the buffer, repeat the command to see the speed of the buffer-cache:
	buffer=$(dd if="$filepath" of=/dev/null bs=1M count=$size 2>&1 || echo "error $?")
	$verbose && echo "$buffer"
	[[ "$buffer" = *error* ]] && { echo "$buffer"; return 1; }
	buffer=${buffer##*,*([!0-9])}; if [[ "$buffer" = *GB* ]]; then buffers+=($((${buffer%%+([!0-9])*} * 1024 * 1024))); elif [[ "$buffer" = *MB* ]]; then buffers+=($((${buffer%%+([!0-9])*} * 1024))); else buffers+=(${buffer%%+([!0-9])*}); fi
	sleep 0.1
	
	rm -f "$filepath" || return $?
	i=$((i+1))
done

total=0
for var in "${reads[@]}"
do
    total=$((total + var))
done
read_average=$((total/number)); sp="KB/s";
[ "$((read_average / 1024))" -ne "0" ] && { read_average=$((read_average / 1024)); sp="MB/s"; }
echo "Read Speed: $read_average $sp"

total=0
for var in "${writes[@]}"
do
    total=$((total + var))
done
write_average=$((total/number)); sp="KB/s";
[ "$((write_average / 1024))" -ne "0" ] && { write_average=$((write_average / 1024)); sp="MB/s"; }
echo "Write Speed: $write_average $sp"

total=0
for var in "${buffers[@]}"
do
    total=$((total + var))
done
buffer_average=$((total/number)); sp="KB/s";
[ "$((buffer_average / 1024))" -ne "0" ] && { buffer_average=$((buffer_average / 1024)); sp="MB/s"; }
echo "Buffer Speed: $buffer_average $sp"
}

lsof_u() {
lsof | cut -d $'\t' -f 3 | while IFS= read -r line; do
	[ -f "$line" ] && du -Lm "$line"
done |
sort -u -k2 -t$'\t' | sort -r -nk1 -t$'\t' |
awk '$1 != "0" {sum += $1; print} END {printf( "Total Size: %s MB\n", sum )}'
}

cached() {
local size=1000k
fincore -h >/dev/null 2>&1 || { echo "command fincore not found"; return 1; }
[ "$1" =  "-s" ] && { size=$2; shift 2; }
if [ $# -gt 0 ]; then 
	find -L "$@" -size +$size -exec fincore -n -o RES,FILE -- {} \;
else tr '\n' '\0' | xargs -0 -- fincore -n -o RES,FILE --; fi |
sed -r '/^ *0B/d; s/^ *([0-9.]*)(.)/\2 \1/; s/^G/N/' | sort -k 1,1 -k 2,2n -t ' ' | sed -r 's/^N/G/; s/^(.) ([0-9.]*)/\2\1/' |
awk '$1 ~ /[0-9.]+G/ {i=1073741824} $1 ~ /[0-9.]+M/ {i=1048576} $1 ~ /[0-9.]+K/ {i=1024} {print; gsub(/[^0-9.]/, "", $1); sum += $1 * i} END {printf( "Total Size: %s MB\n", sum / 1048576 )}'
}

start_zram() {
local arg i nr_multi_zram nr_zramdev sz_zram compr_zram use_mod swap_prio=100 mks opt i=0 j=0 nr_diff nr_current_zram PS nr_builtin_zram zramdev SI
if [ -f /system/bin/swapon ]; then
    SI="/system/bin/swapon"
else
    SI="swapon"
fi
################### Default Config
PS="$(find /proc -name 'swap*' -maxdepth 1 | head -n 1)"

#nr_zramdev=${NR_CPU_CORE}; 	# number of zram devices
#compr_zram=lz4;	# compress algorthm, you can set "compr_zram=lzo" or "compr_zram=lz4"
#nr_multi_zram=1; # compress streams per zram device


nr_current_zram=$(grep -c "^[$(printf '\t ')]*/dev/.*zram" $PS); : ${nr_current_zram:=0}
nr_builtin_zram=$(find /dev/block/zram* -maxdepth 0 | wc -l); : ${nr_builtin_zram:=0}

OPTIND=1; while getopts :n:s:m:c:h opt; do
	case "$opt" in
		n) [ -z "${OPTARG##*[!0-9]*}" ] && { printf 'Error: bad number "%s"\n' "$OPTARG" 1>&2; return 1; }; nr_zramdev=$OPTARG;;
		s) [ -z "${OPTARG##*[!0-9]*}" ] && { printf 'Error: bad number "%s"\n' "$OPTARG" 1>&2; return 1; }; sz_zram=$((OPTARG*1048576/4)); sz_zram=$((sz_zram*4));;
		m) [ -z "${OPTARG##*[!0-9]*}" ] && { printf 'Error: bad number "%s"\n' "$OPTARG" 1>&2; return 1; }; nr_multi_zram=$OPTARG;;
		c) compr_zram=$OPTARG;;
	    h) show_help; return;;	   
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; return 1;;
		*) show_help; return 1;;		
	esac
done; shift "$((OPTIND-1))"

modpath=/system/lib/modules/zram.ko
modargs="num_devices=${nr_zramdev}"

[ "$((sz_zram * nr_zramdev))" -gt "$((RAM_SIZE_KB * 2 * 1024))" ] && { echo "Total zram size is greater than twice the size of memory"; return 1; }
[ "$nr_multi_zram" -gt "$NR_CPU_CORE" ] && { echo "Total compress streams is greater than cpu cores"; return 1; }

# load kernel module for zram
if [ -n "${nr_zramdev+z}" ]; then
	[ "$#" -gt "0" ] && { echo "Unknown options: $*"; return 1; }
	if [ "$nr_current_zram" -gt "$nr_zramdev" ]; then	
		j=$nr_zramdev; while [[ "$j" -lt "$nr_current_zram" ]]; do
			stop_zram $j
			j=$((j+1))
		done; j=0
	elif [ "$nr_zramdev" -gt "$nr_builtin_zram" ]; then
		if [ -f /sys/class/zram-control/hot_add ]; then
			j=$nr_builtin_zram; while [[ "$j" -lt "$nr_zramdev" ]]; do
				cat /sys/class/zram-control/hot_add >/dev/null
				((j++))
			done; j=0
		elif [ -f "$modpath" ]; then
			stop_zram -ar
			echo "Loading zram module"
			insmod "$modpath" "$modargs" || { echo "...failed, error $?"; return 1; };
		elif [ "$nr_builtin_zram" -ne "0" ]; then
			[ -n "${sz_zram+z}" ] && { sz_zram=$(((sz_zram * nr_zramdev) / nr_builtin_zram)); echo "Using built-in zram devices '$nr_builtin_zram' with disk size '${sz_zram}'"; }
			nr_zramdev=${nr_builtin_zram}
		else
			echo "Cant add zram devices. zram module doesnt exist"
			return 1
		fi
	fi
else
	[ -z "${1+z}" ] &&  { echo "no zram device specified"; return 1; }
	[ -z "${1##*[!0-9]*}" ] && { printf 'Error: bad number "%s"\n' "$1" 1>&2; return 1; }; i=$nr_zramdev; nr_zramdev=$((i+1))
	[ "$nr_builtin_zram" -gt "$nr_zramdev" ] || { echo "no zram device $nr_zramdev"; return 1; }
	i=$nr_zramdev
fi
# initialize and configure the zram devices as a swap partition
while [[ "$i" -lt "$nr_zramdev" ]]; do
	mks=false
	if [ "$compr_zram" ] && [ -f "/sys/block/zram${i}/comp_algorithm" ] && grep -q "$compr_zram" "/sys/block/zram${i}/comp_algorithm" && ! grep -q "\[$compr_zram\]" "/sys/block/zram${i}/comp_algorithm"; then		
		stop_zram $i
		echo "Setting zram${i} compression algorithm to $compr_zram"
		echo "$compr_zram" > "/sys/block/zram${i}/comp_algorithm"
	fi	
	if [ "$nr_multi_zram" ] &&  [ -f "/sys/block/zram${i}/max_comp_streams" ] && [ "$(cat "/sys/block/zram${i}/max_comp_streams")" -ne "$nr_multi_zram" ]; then
		stop_zram $i
		echo "Setting zram${i} max streams to $nr_multi_zram"
		echo "$nr_multi_zram" > "/sys/block/zram${i}/max_comp_streams"
	fi
	if { [ "$sz_zram" ] && [ "$(cat "/sys/block/zram${i}/disksize")" -ne "$sz_zram" ]; } || [ "$(cat "/sys/block/zram${i}/disksize")" -eq 0 ]; then
		: ${sz_zram:=$((((RAM_SIZE_KB/4) / nr_zramdev) * 1024))}
		stop_zram -r $i
		echo "Setting zram${i} size to $((sz_zram / 1048576))MB"
		echo "$sz_zram" > "/sys/block/zram${i}/disksize"
		mks=true
	fi
	if $mks || ! blkid "/dev/block/zram${i}" | grep -iq "TYPE=\"swap\""; then
		stop_zram $i
		echo "Formatting zram${i}"
		mkswap /dev/block/zram${i} || { echo "...failed, error $?"; return 1; }
	fi
	sleep 0.1
	if ! grep -q "^[$(printf '\t ')]*/dev/.*zram${i}" $PS; then
		echo "Turning swap on zram${i}"
		$SI -p $swap_prio /dev/block/zram${i} || { echo "...failed, error $?"; return 1; }
	fi
	((i++))
	((swap_prio++))
done
}

stop_zram() {
local zram_devices arg file all=false reset=false PS SO

PS="$(find /proc -name 'swap*' -maxdepth 1 | head -n 1)"
if [ -f /system/bin/swapoff ]; then
    SO="/system/bin/swapoff"
else
    SO="swapoff"
fi

OPTIND=1; while getopts :rah opt; do
	case "$opt" in
		r) reset=true;;
		a) all=true;;
	    h) show_help; return;;	   
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		*) show_help; return 1;;		
	esac
done; shift "$((OPTIND-1))"

if $all; then
	zram_devices=$(awk '$1 ~ /\/dev\/.*zram/{print $1}' $PS)
else
	for file; do
		zram_devices=$(printf "%s${zram_devices:+\n}%s" "$zram_devices" "$(awk -v swap="zram$file" '$1 ~ "\/dev\/.*" swap{print $1}' $PS)")
	done
fi

if [ "$zram_devices" ]; then
	while IFS= read -r i; do
		echo "Stopping zram${i##*zram}"
		if [ -f /sys/class/zram-control/hot_remove ]; then
			echo "${i##*zram}" > /sys/class/zram-control/hot_remove
		else
			$SO "$i"
		fi
		$reset && echo 1 > "/sys/block/zram${i##*zram}/reset"
	done <<< "$zram_devices"
fi
if $all && $reset && lsmod | grep -q zram; then
    echo "unloading zram module"
	rmmod zram || { echo "zram unload fail with error $?"; return 1; }
fi
}

start_swap() {
local file filepath filemb freemb padmb priority PS SI
if [ -f /system/bin/swapon ]; then
    SI="/system/bin/swapon"
else
    SI="swapon"
fi

PS="$(find /proc -name 'swap*' -maxdepth 1 | head -n 1)"
for file; do case $file in 
/dev/*) filepath="${file}"; priority=20;;
*) filepath="${file%:*}"
	filemb="${file##*:}"; 
	[ ! -z "${filemb##*[!0-9]*}" ] || { echo "Indistinctive swap size $filepath"; continue; }
	
	if [ -d "$filepath" ]; then
		filepath="$filepath/swapfile"
	else 
		mkdir -p "${filepath%/*}" || continue
	fi
	
	filepath="$(readlink -f -- "$filepath")"
	[ -d /data/media/0 ] && filepath=${filepath/#\/storage\/emulated\/*([0-9])/\/data\/media\/0}
		
	if [ ! -f "$filepath" ]; then
		echo "Making swap file $filepath"
    else
		filemb=$((filemb - $(du -Lm "$filepath" | cut -f1)))
		if [ "${filemb#-}" -lt 5 ]; then
			filemb="0"
		else
			echo "Changing swap file $filepath size to ${filemb}MB"
		fi
	fi
	if [ "$filemb" -ne 0 ]; then
		freemb=$(df -P "${filepath%/*}" | awk 'NR==2 {print $4}')
		padmb=$((freemb - (100 * 1024)))
		if [ "$padmb" -lt "$((filemb * 1024))" ]; then
			echo "do not have ${filemb}MB + 100MB space for swap file $filepath"	
			continue
		fi
		if grep -q "^[$(printf '\t ')]*$filepath" "$PS"; then swapoff "$filepath" || continue; fi
		if [ "$filemb" -gt 0 ]; then 
			dd if=/dev/zero bs=1048576 count="$filemb" >>"$filepath" || continue
		else
			truncate -s "$(($(du -Lm "$filepath" | cut -f1) + filemb))" "$filepath"
		fi
		echo " ...done."
		sleep 0.1
	fi
	chmod 600 "$filepath"
	case $filepath in
	/data/|/cache/|/system/) priority=15;;
	/sdcard/*) priority=10;;
	*) priority=5;;
	esac
;;
esac
	if ! blkid "$filepath" | grep -iq "TYPE=\"swap\"" || [ "$filemb" -ne 0 ]; then
		echo "Formatting $filepath"
		mkswap "$filepath" || continue;
		echo " ...done."
		sleep 0.1
	fi
	if grep -q "^[$(printf '\t ')]*$filepath" "$PS"; then
		echo "Already swapped on $filepath"
	else
		echo "Turning swap on $filepath"
		$SI -p $priority "$filepath"
		echo " ...done."
		sleep 0.1
	fi
done
}

stop_swap() {
local swapfiles file=false partition=false zram=false all=false PS SO
PS="$(find /proc -name 'swap*' -maxdepth 1 | head -n 1)"
if [ -f /system/bin/swapoff ] ; then
    SO="/system/bin/swapoff"
else
    SO="swapoff"
fi
OPTIND=1; while getopts :apfzh opt; do
	case "$opt" in
		a) all=true;;
		p) partition=true;;
		f) file=true;;
		z) zram=true;;
	    h) show_help; return;;	   
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; return 1;;
		*) show_help; return 1;;		
	esac
done; shift "$((OPTIND-1))"

if $all; then
	swapfiles=$(awk 'NR>1 {print $1}' $PS)
elif [ "$OPTARG" -gt "1" ]; then
	$file && swapfiles=$(printf "%s${swapfiles:+\n}%s" "$swapfiles" "$(awk 'NR>1 && $2 ~ /file/{print $1}' $PS)")
	$partition && swapfiles=$(printf "%s${swapfiles:+\n}%s" "$swapfiles" "$(awk 'NR>1 && $1 !~ /\/dev\/.*zram/ && $2 ~ /partition/{print $1}' $PS)")
	$zram && swapfiles=$(printf "%s${swapfiles:+\n}%s" "$swapfiles" "$(awk '$1 ~ /\/dev\/.*zram/{print $1}' $PS)")
else
	for file; do
		swapfiles=$(printf "%s${swapfiles:+\n}%s" "$swapfiles" "$(awk -v swap="$file" '$1==swap{print $1}' $PS)")
	done
fi

if [ "$swapfiles" ]; then
	while IFS= read -r swap; do
		case $swap in
		/dev/*zram*) stop_zram "${swap##*zram}"
		;;
		*)	echo "Turning off swap $swap"
			$SO "$swap" || { echo "...failed, error $?"; return 1; }
			sleep 0.1
			[ -f "$swap" ] && rm -f "$swap"
		;;
		esac
	done <<<"$swapfiles"
fi
}

adb() (
for opt; do arg="$arg $(esc "$opt")"; done
b=$arg su shell --shell /system/bin/sh --preserve-environment --command 'PREFIX=adb; . /data/env_variables; eval "$b"'
arg=$?
stty sane 2>/dev/null
return $arg
)

install_apk() {
if [ "$1" = "-f" ]; then
 if [ -f "$2" ]; then cat "$2"; else { echo "$2: not a file" 1>&2; return 1; }; fi
else
 printf '%s\n' "$@"
fi | while IFS= read -r line; do
 [ -f "$line" ] && adb pm install -r "$line"
done
}

apk_path(){
packages=$(mktemp)
if [ "$API" -gt 23 ]; then
	adb cmd package list packages -f || { echo "can't create packages file" 1>&2; exit 1; }
else
	adb pm list packages -f || { echo "can't create packages file" 1>&2; exit 1; }
fi > "$packages"
if [ "$1" = "-f" ]; then
 if [ -f "$2" ]; then cat "$2"; else { echo "$2: not a file" 1>&2; return 1; }; fi
else
 printf '%s\n' "$@"
fi | while IFS= read -r line; do
	path="$(grep "$line\$" "$packages" | cut -d ':' -f2 | cut -d '=' -f1)"; [ "$path" ] && echo "$path"
done
#rm -f "$packages" 2>/dev/null
}

NR_CPU_CORE="$(grep -c "^processor" /proc/cpuinfo)"; [ "$NR_CPU_CORE" -eq 0 ] && NR_CPU_CORE=1; export NR_CPU_CORE;
RAM_SIZE_KB="$(awk '/MemTotal/{print $2}' /proc/meminfo)"; export RAM_SIZE_KB;
