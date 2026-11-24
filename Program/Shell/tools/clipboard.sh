#!/bin/sh
if test ! -t 0; then
    stdin=`cat; echo x`; stdin=${stdin%x}
fi

cl_paste() {
if [ "$ENVIRONMENT" = termux ]; then
    termux-clipboard-get
elif [ "$ENVIRONMENT" = wsl ]; then
	powershell.exe -command "Get-Clipboard" | sed -e 's/\r$//' -e '${/^$/d;}'
else
    xclip -selection c -o
fi
}

cl_copy() {
if [ "$ENVIRONMENT" = termux ]; then
    printf '%s' "$stdin" | termux-clipboard-set
elif [ "$ENVIRONMENT" = wsl ]; then
    # printf '%s' "$stdin" | clip.exe
    # printf '%s' "$stdin" | powershell.exe -command "Set-Clipboard"
	 printf '%s' "$stdin" | xclip -selection c
else
    printf '%s' "$stdin" | xclip -selection c
fi
}

. $HOME/lib/get_arch.lib.sh

OPTIND=1; while getopts :cv opt; do
	case "$opt" in
		v) cl_paste;;
		c) cl_copy;;  
	   \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; return 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; return 1;;
		*) return 1;;		
	esac
done; shift "$((OPTIND-1))"