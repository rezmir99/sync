#!/bin/bash
[ -z "$PERM_GIT_PATH" ] && { echo "no PERM_GIT_PATH"; exit 1; }
SERVER_PROFILE_PATH="$PERM_GIT_PATH/ProgramData/server_profile.sh"

cd $HOME

# make profile
cp -af "$SERVER_PROFILE_PATH" "$HOME/server_profile.sh"
grep -q '^[.] '"$HOME/server_profile.sh" "$HOME/.bashrc" || echo ". $HOME/server_profile.sh" >> "$HOME/.bashrc"

# make dirs
sudo mkdir -p /usr/local/lib /usr/local/bin

# sync shell
. "$PERM_GIT_PATH"/Program/Shell/setup_server/sync_server.sh

# global 
. "$HOME/server_profile.sh"
