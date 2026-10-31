#!/bin/bash
. "$HOME/server_profile.sh"

type=$1

bin_path="$PERM_GIT_PATH/Program/Linux/ssh-tunnel"

[ -z "$type" ] && { echo 'error: empty type'; exit 1; }

# make services
sudo cat "$bin_path/ssh-$type-tunnel.service" > /etc/systemd/system/ssh-$type-tunnel.service
sudo cat "$bin_path/ssh-$type-tunnel_restart.service" > /etc/systemd/system/ssh-$type-tunnel_restart.service
sudo cat "$bin_path/ssh-$type-tunnel_restart.timer" > /etc/systemd/system/ssh-$type-tunnel_restart.timer

# reload
sudo systemctl daemon-reload
