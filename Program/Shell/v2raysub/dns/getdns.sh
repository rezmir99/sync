    #!/bin/bash
. $HOME/ProgramData/v2raysub/global.sh

database='https://raw.githubusercontent.com/cslev/encrypted_dns_resolvers/main/doh_resolvers_data_20230510.json'

curl -Lk --fail --silent --show-error -X GET "$database" \
| jq -r '.[] | .uri' > "$SOURCE/DNS.all.txt"
