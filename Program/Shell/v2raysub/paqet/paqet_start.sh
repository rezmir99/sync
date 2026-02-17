#!/bin/bash

# enable on boot
sudo systemctl enable paqet.service
sudo systemctl enable --now paqet_restart.timer
sudo systemctl enable paqet_restart.service
systemctl list-unit-files paqet_firewall.service &>/dev/null &&  sudo systemctl enable paqet_firewall.service

# start
systemctl list-unit-files paqet_firewall.service &>/dev/null && systemctl start paqet_firewall.service
systemctl start paqet.service
systemctl start paqet_restart.service
