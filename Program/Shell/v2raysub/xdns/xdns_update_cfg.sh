. "$HOME/server_profile.sh"
bin_path="$PERM_GIT_PATH/Program/Linux/xdns"

sync_server
cp -f /root/xray-core/config.json /root/xray-core/config.json.bak
cp -f "$bin_path/config.json" /root/xray-core/config.json
systemctl restart xdns
