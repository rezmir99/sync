#!/bin/bash

. "$HOME/server_profile.sh"
today=$(date +"%Y-%m-%d-%H%M%S")

server=$1

config_path="$PERM_GIT_PATH/Program/VPN/Config/paqet/config.$server.yaml"
bin_path="$PERM_GIT_PATH/Program/Linux/paqet"

[ -f "$config_path" ] || { echo 'error: paqet_update: wrong server config path'; exit 1; }

# chk role
if grep -q '^role: "client"' $config_path; then
    role=client
else
    role=server
fi

# find version
paqet_version=$(head -n 1 "$config_path" | sed 's/^#//')

# make backup
if [ -s "/root/paqet/config.yaml" ]; then
    paqet_version_old=$(head -n 1 "/root/paqet/config.yaml" | sed 's/^#//')
    echo "backing up /root/paqet to /root/paqet_backup/$paqet_version_old"
    mkdir -p "/root/paqet_backup/$paqet_version_old"
    cp -af "/root/paqet/." "/root/paqet_backup/$paqet_version_old/"
fi

# update bin & cfg
rm -rf /root/paqet
mkdir -p /root/paqet
tar xzf "$PERM_GIT_PATH/Program/Linux/paqet/paqet-linux-amd64-$paqet_version.tar.gz" -C /root/paqet/
cp -af "$config_path" /root/paqet/config.yaml
chmod 0755 /root/paqet/paqet_linux_amd64

# cp firewall rules
if [ "$role" =  server ]; then
    cp -f "${config_path%/*}/firewall.sh" "/root/paqet/firewall.sh"
    chmod 755 "/root/paqet/firewall.sh"
    sudo cat "$bin_path/paqet_firewall.service" > /etc/systemd/system/paqet_firewall.service
fi

# reload
sudo systemctl daemon-reload

# restart
systemctl restart paqet.service

