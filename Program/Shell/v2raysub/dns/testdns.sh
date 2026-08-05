    #!/bin/bash
. $HOME/ProgramData/v2raysub/global.sh

sortdns
clipboard -v > $SOURCE/dns.cf
cpsub dnstester tmp
setcfip -P -I dns.cf -m a tmp
mkxraynode tmp
getfragsub tmp
