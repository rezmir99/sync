#!/bin/bash
mkdir -p /root/xdns
cp -f /root/xdns/xray_backup /root/xray-core/xray
cp -f /root/xdns/config.json_backup /root/xray-core/config.json 

systemctl restart xdns
