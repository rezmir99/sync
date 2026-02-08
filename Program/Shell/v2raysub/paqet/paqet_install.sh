#!/bin/bash
. "$HOME/server_profile.sh"

server=$1

config_path="$PERM_GIT_PATH/Program/VPN/Config/paqet/config.$server.yaml"
bin_path="$PERM_GIT_PATH/Program/Linux/paqet"

[ -f "$config_path" ] || { echo 'error: paqet_install: wrong server config path'; exit 1; }
mkdir -p /root/paqet

# chk role
if grep -q '^role: "client"' $config_path; then
    role=client
else
    role=server
fi

# make services
sudo cat "$bin_path/paqet.service" > /etc/systemd/system/paqet.service
sudo cat "$bin_path/paqet_restart.service" > /etc/systemd/system/paqet_restart.service
sudo cat "$bin_path/paqet_restart.timer" > /etc/systemd/system/paqet_restart.timer

# cp firewall rules
if [ "$role" =  server ]; then
    cp -f "${config_path%/*}/firewall.sh" "/root/paqet/firewall.sh"
    chmod 755 "/root/paqet/firewall.sh"
    sudo cat "$bin_path/paqet_firewall.service" > /etc/systemd/system/paqet_firewall.service
fi

# reload
sudo systemctl daemon-reload

# update paqet
paqet_update $server
