PERM_GIT_URL='https://www.github.com/rezmir99/sync.git'
PERM_GIT_DIR=$(echo "${PERM_GIT_URL##*/}" | cut -d '.' -f 1)

cd $HOME
git clone "$PERM_GIT_URL"
chmod 755 $HOME/$PERM_GIT_DIR/Program/Shell/setup_server/setup_server.sh
$HOME/$PERM_GIT_DIR/Program/Shell/setup_server/setup_server.sh
