#!/bin/bash
version=$1

[ -d "/root/paqet_backup/$version" ] || { echo "version not found"; exit 1; }
cp -af  "/root/paqet_backup/$version/." "/root/paqet/"
systemctl restart paqet.service
