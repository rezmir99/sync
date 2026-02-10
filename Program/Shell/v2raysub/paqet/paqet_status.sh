#!/bin/bash

sudo systemctl status paqet.service
sudo systemctl status paqet_restart.timer
sudo systemctl status paqet_restart.service
systemctl list-unit-files paqet_firewall.service &>/dev/null &&  sudo systemctl status paqet_firewall.service
