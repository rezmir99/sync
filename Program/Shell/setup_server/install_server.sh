cd $HOME
. $HOME/.profile

git clone "$PERM_GIT_URL"
chmod 755 $HOME/sync/Program/Shell/setup_server/setup_server.sh
$HOME/sync/Program/Shell/setup_server/setup_server.sh
