# set PERM_GIT_URL in this file and also HOME/ProgramData/server_profile.sh
export PERM_GIT_URL='https://www.github.com/rezmir99/sync.git'


export PERM_GIT_PATH="$HOME/$(echo "${PERM_GIT_URL##*/}" | cut -d '.' -f 1)"
cd $HOME
git clone "$PERM_GIT_URL"
chmod 755 $HOME/$PERM_GIT_PATH/Program/Shell/setup_server/setup_server.sh

$PERM_GIT_PATH/Program/Shell/setup_server/setup_server.sh
