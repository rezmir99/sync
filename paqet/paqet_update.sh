#!/bin/bash

. "$HOME/server_profile.sh"
today=$(date +"%Y-%m-%d-%H%M%S")

server=$1

config_path="$PERM_GIT_PATH/Program/VPN/Config/paqet/config.$server1.yaml"
bin_path="$PERM_GIT_PATH/Program/Linux/paqet"

[ -f "$config_path" ] || { echo 'error: wrong server config path'; exit 1; }

# find version
paqet_version=$(head -n 1 "$config_path" | sed 's/^#//')

# make backup
paqet_version_old=$(head -n 1 "/root/paqet/config.yaml" | sed 's/^#//')
echo "backing up /root/paqet to /root/paqet_backup/$paqet_version_old"
mkdir -p "/root/paqet_backup/$paqet_version_old"
cp -af "/root/paqet/." "/root/paqet_backup/$paqet_version_old/"

# update bin & cfg
rm -rf /root/paqet
mkdir -p /root/paqet
tar xzf paqet-linux-amd64-$paqet_version.tar.gz -C /root/paqet/
cp -af "$config_path" /root/paqet/config.yaml
chmod 0755 /root/paqet/paqet_linux_amd64

# restart
systemctl restart paqet.service

