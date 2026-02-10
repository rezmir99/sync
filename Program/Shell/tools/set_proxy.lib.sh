#!/bin/sh
#. $HOME/lib/get_arch.lib.sh

# if [ "$ENVIRONMENT" = wsl ]; then  
#     export HOSTIP=$(ip route show | grep -i default | awk '{ print $3}')
# else
#     export HOSTIP='127.0.0.1'
# fi

export HOSTIP='127.0.0.1'

set_proxy() {
[ -z "$1" ] && { echo "no port spcified"; return 1; }
export http_proxy="http://${HOSTIP}:$1"
export HTTP_PROXY="http://${HOSTIP}:$1"
export HTTPS_PROXY="http://${HOSTIP}:$1"
export https_proxy="http://${HOSTIP}:$1"
export NO_PROXY='localhost,127.0.0.1,::1'
export no_proxy='localhost,127.0.0.1,::1'

export ALL_PROXY="socks5h://${HOSTIP}:$1"
export all_proxy="socks5h://${HOSTIP}:$1"

git config --global http.proxy "http://${HOSTIP}:$1"
set_proxy_apt $1
}

clear_proxy(){
unset http_proxy HTTPS_PROXY no_proxy NO_PROXY https_proxy HTTP_PROXY ALL_PROXY all_proxy
git config --global --unset http.proxy
clear_proxy_apt
}

set_proxy_apt_func() {
    sudo echo "Acquire::http::Proxy \"http://$HOSTIP:$1\";" > "/etc/apt/apt.conf.d/proxy.conf"   
    sudo echo "Acquire::https::Proxy \"http://$HOSTIP:$1\";" >> "/etc/apt/apt.conf.d/proxy.conf"
}

set_proxy_apt() {
sudo -E bash -c ". $HOME/lib/set_proxy.lib.sh; set_proxy_apt_func $1"
}

clear_proxy_apt() {
sudo -E bash -c "rm -f /etc/apt/apt.conf.d/proxy.conf"
}
