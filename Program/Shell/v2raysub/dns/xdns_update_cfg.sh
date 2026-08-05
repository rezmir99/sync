# truncate -s 0 /root/xray-core/config.json.bak
# nano /root/xray-core/config.json.bak
cp -f /root/xray-core/config.json.bak /root/xray-core/config.json
systemctl restart xdns
