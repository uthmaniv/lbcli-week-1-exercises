# Check if the address is valid, return only true or false
# Address: bcrt1qckgvfee4qs6y98jrcn8qc0m6ce6sxls0vac3yy
bitcoin-cli -regtest validateaddress "bcrt1qckgvfee4qs6y98jrcn8qc0m6ce6sxls0vac3yy" | jq -r '.isvalid'
