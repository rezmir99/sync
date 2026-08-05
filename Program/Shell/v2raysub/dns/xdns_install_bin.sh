# truncate -s 0 /root/xray-core/config.json.bak
# nano /root/xray-core/config.json.bak

mkdir -p /root/xray-core

bin_name="xray-knife"
bin_link='https://github.com/lilendian0x00/xray-knife/releases/latest/download/Xray-knife-android-arm64-v8a.zip'
bin_zip=$(basename -- "$bin_link")
cd /root/xray-core
rm -f "$bin_zip"
wget --no-verbose $bin_link && echo bin updated  || echo bin not updated
unzip -o "$bin_zip"
chmod +x "$bin_name"

systemctl restart xdns
