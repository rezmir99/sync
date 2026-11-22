#!/bin/bash
. "$HOME/server_profile.sh"
bin_path="$PERM_GIT_PATH/Program/Linux/xdns"

unset config
OPTIND=1; while getopts :c: opt; do
	case "$opt" in
        c) config="$OPTARG";;
        \?) printf 'Error: Unknown option "--%s"\n' "$OPTARG" 1>&2; exit 1;;
		:) printf 'Error: "--%s" requires an argument\n' "$OPTARG" >&2; exit 1;;
		*) exit 1;;
	esac
done; shift "$((OPTIND-1))"


sync_server || { echo "cant sync_server"; exit 1; }

sudo cat "$bin_path/xdns.service" >  /etc/systemd/system/xdns.service
sudo cat "$bin_path/xdns_restart.service" >  /etc/systemd/system/xdns_restart.service
sudo cat "$bin_path/xdns_restart.timer" >  /etc/systemd/system/xdns_restart.timer
[[ "$config" =~ xdns ]] && sudo cat "$bin_path/xdns_firewall.service" >  /etc/systemd/system/xdns_firewall.service

sudo systemctl daemon-reload

mkdir -p /root/xdns
sudo cat "$bin_path/firewall.sh" > /root/xdns/firewall.sh
chmod 0755 /root/xdns/firewall.sh

# install bin
xdns_update_bin

# install cfg
xdns_update_cfg ${config:+-c "$config"}

# enable on boot
xdns_start
