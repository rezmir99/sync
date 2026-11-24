#!/bin/bash
[ -s "$HOME/server_profile.sh" ] || { echo 'error: no server_profile'; exit 1; }
. "$HOME/server_profile.sh"

service_name=$1

sudo cat "$PERM_GIT_PATH/Program/Linux/$service_name" > /etc/systemd/system/${service_name##*/}

# reload
sudo systemctl daemon-reload
