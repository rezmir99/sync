#!/bin/bash
version=$1

cp -af  "/root/paqet_backup/$version/." "/root/paqet/"
systemctl restart paqet.service
