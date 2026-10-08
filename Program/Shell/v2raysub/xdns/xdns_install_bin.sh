# truncate -s 0 /root/xray-core/config.json.bak
# nano /root/xray-core/config.json.bak

mkdir -p /root/xray-core

bin_name="xray"
bin_link='https://github.com//XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip'
bin_zip=$(basename -- "$bin_link")
cd /root/xray-core
rm -f "$bin_zip"
wget --no-verbose $bin_link && echo bin updated  || echo bin not updated
unzip -o "$bin_zip"
chmod 755 "$bin_name"

systemctl restart xdns 2>/dev/null
