#!/bin/bash
for UNIT in ssh-reverse-tunnel_restart.timer ssh-reverse-tunnel_restart.service ssh-reverse-tunnel.service ssh-direct-tunnel_restart.timer ssh-direct-tunnel_restart.service ssh-direct-tunnel.service; do
    if systemctl list-unit-files "$UNIT" --no-legend | grep -q .; then
        sudo systemctl restart "$UNIT"
        sudo systemctl enable --now "$UNIT"
    fi
done
