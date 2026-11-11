#!/bin/bash
. "$HOME/server_profile.sh"
bin_path="$PERM_GIT_PATH/Program/Linux"

bin_name="aether"
bin_link='https://github.com/CluvexStudio/Aether/releases/latest/download/aether-linux-x86_64.tar.gz'
bin_zip=$(basename -- "$bin_link")
bin_dir='/root/aether'

mkdir -p "$bin_dir"
cd "$bin_dir"
rm -f "$bin_zip"
wget --no-verbose $bin_link && echo bin updated  || echo bin not updated
tar -xzf aether-linux-x86_64.tar.gz
chmod 755 "$bin_name"

sudo cat "$bin_path/aether.service" >  /etc/systemd/system/aether.service
sudo systemctl daemon-reload
