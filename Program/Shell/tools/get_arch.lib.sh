set -a

ENVIRONMENT=linux
[ -z $(echo $PREFIX | grep -o "com.termux") ] || ENVIRONMENT=termux
grep -qi microsoft /proc/version 2>/dev/null && ENVIRONMENT=wsl

set +a