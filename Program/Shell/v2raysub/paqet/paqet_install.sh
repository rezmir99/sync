#!/bin/bash
. "$HOME/server_profile.sh"

server=$1

config_path="$PERM_GIT_PATH/Program/VPN/Config/paqet/config.$server.yaml"
bin_path="$PERM_GIT_PATH/Program/Linux/paqet"

[ -f "$config_path" ] || { echo 'error: paqet_install: wrong server config path'; exit 1; }
mkdir -p /root/paqet

# make services
sudo cat "$bin_path/paqet.service" > /etc/systemd/system/paqet.service
sudo cat "$bin_path/paqet_restart.service" > /etc/systemd/system/paqet_restart.service
sudo cat "$bin_path/paqet_restart.timer" > /etc/systemd/system/paqet_restart.timer

# update paqet
paqet_update $server
