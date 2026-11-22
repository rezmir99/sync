#!/bin/bash
systemctl stop xdns.service
systemctl list-unit-files "xdns_firewall.service" --no-legend | grep -q . && systemctl stop xdns_firewall.service
systemctl stop xdns_restart.service

sudo systemctl disable xdns.service
sudo systemctl disable --now xdns_restart.timer
sudo systemctl disable xdns_restart.service
systemctl list-unit-files "xdns_firewall.service" --no-legend | grep -q . && sudo systemctl disable xdns_firewall.service
