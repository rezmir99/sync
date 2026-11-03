#!/bin/bash
systemctl stop xdns.service
systemctl stop xdns_firewall.service
systemctl stop xdns_restop.service

sudo systemctl disable xdns.service
sudo systemctl disable --now xdns_restop.timer
sudo systemctl disable xdns_restop.service
sudo systemctl disable xdns_firewall.service
