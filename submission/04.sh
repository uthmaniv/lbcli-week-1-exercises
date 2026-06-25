# Create a wallet named "builderswallet" and fund it
bitcoin-cli -regtest createwallet "builderswallet"
bitcoin-cli -regtest generatetoaddress 101 "$(bitcoin-cli -regtest getnewaddress)"
