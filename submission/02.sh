# Get the bitcoin node network name
bitcoin-cli -regtest getblockchaininfo | jq -r '.chain'
