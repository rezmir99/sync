#!/bin/bash
# stop
systemctl list-unit-files paqet_firewall.service &>/dev/null && systemctl stop paqet_firewall.service
systemctl stop paqet.service
systemctl stop paqet_restart.service
systemctl stop paqet_restart.timer

# on boot
sudo systemctl disable paqet.service
sudo systemctl disable paqet_restart.timer
sudo systemctl disable paqet_restart.service
systemctl list-unit-files paqet_firewall.service &>/dev/null &&  sudo systemctl disable paqet_firewall.service
