#!/bin/bash
# enable on boot
sudo systemctl enable xdns.service
sudo systemctl enable --now xdns_restart.timer
sudo systemctl enable xdns_restart.service
sudo systemctl enable xdns_firewall.service

# start
systemctl start xdns.service
systemctl start xdns_firewall.service
systemctl start xdns_restart.service
