#!/bin/bash
# enable on boot
sudo systemctl enable xdns.service
sudo systemctl enable --now xdns_restart.timer
sudo systemctl enable xdns_restart.service
sudo systemctl enable xdns_firewall.service

# start
systemctl restart xdns.service
systemctl restart xdns_firewall.service
systemctl restart xdns_restart.service
