#!/bin/bash
systemctl stop xdns.service
systemctl stop xdns_firewall.service
systemctl stop xdns_restart.service

sudo systemctl disable xdns.service
sudo systemctl disable --now xdns_restart.timer
sudo systemctl disable xdns_restart.service
sudo systemctl disable xdns_firewall.service
