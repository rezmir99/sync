#!/bin/bash
# enable on boot
sudo systemctl enable xdns.service
sudo systemctl enable --now xdns_restart.timer
sudo systemctl enable xdns_restart.service
systemctl list-unit-files "xdns_firewall.service" --no-legend | grep -q . && sudo systemctl enable xdns_firewall.service

# start
systemctl restart xdns.service
systemctl list-unit-files "xdns_firewall.service" --no-legend | grep -q . && systemctl restart xdns_firewall.service
systemctl restart xdns_restart.service
