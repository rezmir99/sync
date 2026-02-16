#!/bin/sh

#. $HOME/lib/get_arch.lib.sh
# if [ "$ENVIRONMENT" = wsl ]; then  
#     export HOSTIP=$(ip route show | grep -i default | awk '{ print $3}')
# else
#     export HOSTIP='127.0.0.1'
# fi

export HOSTIP='127.0.0.1'
export PROXY_TYPE=socks5h

set_proxy_type() {
if [ "$1" = -s ]; then
    export PROXY_TYPE=socks5h
else
    export PROXY_TYPE=http
fi
}

set_proxy() {
OPTIND=1; while getopts :sh opt; do
case "$opt" in
    s) export PROXY_TYPE=socks5h;;
    h) export PROXY_TYPE=http;;
    \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
    :) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
    *) exit 1;;	
esac
done; shift "$((OPTIND-1))"

[ -z "$1" ] && { echo "no port spcified"; return 1; }
export http_proxy="$PROXY_TYPE://${HOSTIP}:$1"
export HTTP_PROXY="$PROXY_TYPE://${HOSTIP}:$1"
export HTTPS_PROXY="$PROXY_TYPE://${HOSTIP}:$1"
export https_proxy="$PROXY_TYPE://${HOSTIP}:$1"
export NO_PROXY='localhost,127.0.0.1,::1'
export no_proxy='localhost,127.0.0.1,::1'

export ALL_PROXY="$PROXY_TYPE://${HOSTIP}:$1"
export all_proxy="$PROXY_TYPE://${HOSTIP}:$1"

git config --global http.proxy "$PROXY_TYPE://${HOSTIP}:$1"
git config --global https.proxy "$PROXY_TYPE://${HOSTIP}:$1"

}

clear_proxy(){
unset http_proxy HTTPS_PROXY no_proxy NO_PROXY https_proxy HTTP_PROXY ALL_PROXY all_proxy
git config --global --unset http.proxy
clear_proxy_apt
}

set_proxy_apt_func() {
sudo echo "Acquire::http::Proxy \"$PROXY_TYPE://$HOSTIP:$1\";" > "/etc/apt/apt.conf.d/proxy.conf"   
sudo echo "Acquire::https::Proxy \"$PROXY_TYPE://$HOSTIP:$1\";" >> "/etc/apt/apt.conf.d/proxy.conf"
}

set_proxy_apt() {
sudo -E bash -c ". $HOME/lib/set_proxy.lib.sh; set_proxy_apt_func $1"
}

clear_proxy_apt() {
sudo -E bash -c "rm -f /etc/apt/apt.conf.d/proxy.conf"
}

