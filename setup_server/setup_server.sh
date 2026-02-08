#!/bin/sh
PERM_GIT_PATH=$(echo "$(dirname "$0")" | rev | cut -d '/' -f 5- | rev)
SERVER_PROFILE_PATH="$PERM_GIT_PATH/ProgramData/server_profile.sh"

# make profile
cp -af "$SERVER_PROFILE_PATH" "$HOME/server_profile.sh"
grep -q '^[.] '"$HOME/server_profile.sh" "$HOME/.bashrc" || echo ". $HOME/server_profile.sh" >> "$HOME/.bashrc"

# make dirs
sudo mkdir -p /usr/local/lib /usr/local/bin

# sync shell
. "$PERM_GIT_PATH"/Program/Shell/setup_server/sync_server.sh

# global 
. "$HOME/server_profile.sh"
