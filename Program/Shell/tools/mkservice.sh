#!/bin/bash
service_name=$1

sudo cat "$HOME/Program/Linux/$service_name" > /etc/systemd/system/${service_name##*/}

# reload
sudo systemctl daemon-reload
