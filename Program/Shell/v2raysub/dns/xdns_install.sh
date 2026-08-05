#!/bin/bash
. "$HOME/server_profile.sh"
bin_path="$PERM_GIT_PATH/Program/Linux/xdns"

sudo cat "$bin_path/xdns.service" >  /etc/systemd/system/xdns.service
sudo cat "$bin_path/xdns_restart.service" >  /etc/systemd/system/xdns_restart.service
sudo cat "$bin_path/xdns_restart.timer" >  /etc/systemd/system/xdns_restart.timer
sudo cat "$bin_path/xdns_firewall.service" >  /etc/systemd/system/xdns_firewall.service

sudo systemctl daemon-reload

mkdir -p xdns
sudo cat "$bin_path/firewall.sh" > /root/xdns/firewall.sh
chmod 0755 /root/xdns/firewall.sh

# enable on boot
sudo systemctl enable xdns.service
sudo systemctl enable --now xdns_restart.timer
sudo systemctl enable xdns_restart.service
sudo systemctl enable xdns_firewall.service

# start
systemctl start xdns.service
systemctl start xdns_firewall.service
systemctl start xdns_restart.service
