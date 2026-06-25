#!/bin/bash

# Import helper functions
source .github/functions.sh

# Week One Exercise: Bitcoin Address Generation and Transaction Verification
# This script demonstrates using the key concepts from previous exercises in a practical scenario

# Ensure script fails fast on errors
set -e

# ========================================================================
# STUDENT EXERCISE PART BEGINS HERE - Complete the following sections
# ========================================================================

# Set up the challenge scenario
setup_challenge

# CHALLENGE PART 1: Create a wallet to track your discoveries
echo "CHALLENGE 1: Create your explorer wallet"
echo "----------------------------------------"
echo "Create a wallet named 'btrustwallet' to track your Bitcoin exploration"
# Create a wallet named "btrustwallet"
bitcoin-cli -regtest createwallet "btrustwallet"

# Create a second wallet that will hold the treasure
echo "Now, create another wallet called 'treasurewallet' to fund your adventure"
# Create a wallet named "treasurewallet"
bitcoin-cli -regtest createwallet "treasurewallet"

# Generate an address for mining in the treasure wallet
TREASURE_ADDR=$(bitcoin-cli -regtest -rpcwallet=treasurewallet getnewaddress)
check_cmd "Address generation"
echo "Mining to address: $TREASURE_ADDR"

# Mine some blocks to get initial coins
mine_blocks 101 $TREASURE_ADDR

# CHALLENGE PART 2: Check your starting balance 
echo ""
echo "CHALLENGE 2: Check your starting resources"
echo "-----------------------------------------"
echo "Check your wallet balance to see what resources you have to start"
# Get the balance of btrustwallet
BALANCE=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getbalance)
check_cmd "Balance check"
echo "Your starting balance: $BALANCE BTC"

# CHALLENGE PART 3: Generate different address types to collect treasures
echo ""
echo "CHALLENGE 3: Create a set of addresses for your exploration"
echo "---------------------------------------------------------"
echo "The treasure hunt requires 4 different types of addresses to collect funds."
echo "Generate one of each address type (legacy, p2sh-segwit, bech32, bech32m)"
# Generate addresses of each type
LEGACY_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" legacy)
check_cmd "Legacy address generation"

P2SH_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" p2sh-segwit)
check_cmd "P2SH address generation"

SEGWIT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" bech32)
check_cmd "SegWit address generation"

TAPROOT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" bech32m)
check_cmd "Taproot address generation"

echo "Your exploration addresses:"
echo "- Legacy treasure map: $LEGACY_ADDR"
echo "- P2SH ancient vault: $P2SH_ADDR"
echo "- SegWit digital safe: $SEGWIT_ADDR"
echo "- Taproot quantum vault: $TAPROOT_ADDR"

# This part is done for you - sending treasures to each address
echo ""
echo "The treasure hunt begins! Coins are being sent to your addresses..."

# Send treasure to each address using our helper function with fee handling
send_with_fee "treasurewallet" "$LEGACY_ADDR" 1.0 "First clue: Verify this transaction"
send_with_fee "treasurewallet" "$P2SH_ADDR" 2.0 "Second clue: Needs validation" 
send_with_fee "treasurewallet" "$SEGWIT_ADDR" 3.0 "Third clue: Check descriptor"
send_with_fee "treasurewallet" "$TAPROOT_ADDR" 4.0 "Final clue: Message verification"

# Mine blocks to confirm the transactions
mine_blocks 6 $TREASURE_ADDR

# CHALLENGE PART 4: Find the total treasure collected
echo ""
echo "CHALLENGE 4: Count your treasures"
echo "-------------------------------"
echo "Treasures have been sent to your addresses. Check how much you've collected!"
# Check wallet balance after receiving funds
NEW_BALANCE=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getbalance)
check_cmd "New balance check"
echo "Your treasure balance: $NEW_BALANCE BTC"

# Calculate how much treasure was collected (new balance minus starting balance)
COLLECTED=$(echo "$NEW_BALANCE - $BALANCE" | bc)
check_cmd "Balance calculation"
echo "You've collected $COLLECTED BTC in treasures!"

# CHALLENGE PART 5: Verify that one of your addresses is valid
echo ""
echo "CHALLENGE 5: Validate the ancient vault address"
echo "--------------------------------------------"
echo "To ensure the P2SH vault is secure, verify it's a valid Bitcoin address"
# Validate the P2SH address
P2SH_VALID=$(bitcoin-cli -regtest -rpcwallet=btrustwallet validateaddress "$P2SH_ADDR" | jq -r '.isvalid')
check_cmd "Address validation"
echo "P2SH vault validation: $P2SH_VALID"

if [[ "$P2SH_VALID" == "true" ]]; then
  echo "Vault is secure! You may proceed to the next challenge."
else
  echo "WARNING: Vault security compromised!"
  exit 1
fi

# CHALLENGE PART 6: Decode a signed message to reveal a secret
echo ""
echo "CHALLENGE 6: Decode the hidden message"
echo "------------------------------------"
echo "You've found a message signed with the legacy address key."
echo "Verify the signature to reveal the hidden message!"

# This part is done for you - creating a signed message
SECRET_MESSAGE="You've successfully completed the Bitcoin treasure hunt!"
SIGNATURE=$(bitcoin-cli -regtest -rpcwallet=btrustwallet signmessage $LEGACY_ADDR "$SECRET_MESSAGE")
check_cmd "Message signing"
echo "Address: $LEGACY_ADDR"
echo "Signature: $SIGNATURE"

# For interactive learning, students would guess the message:
echo "In an interactive environment, you would guess the message content."
echo "For CI testing, we'll verify the correct message directly:"

# Verify the signed message
VERIFY_RESULT=$(bitcoin-cli -regtest -rpcwallet=btrustwallet verifymessage "$LEGACY_ADDR" "$SIGNATURE" "$SECRET_MESSAGE")
check_cmd "Message verification"
echo "Message verification result: $VERIFY_RESULT"

if [[ "$VERIFY_RESULT" == "true" ]]; then
  echo "Message verified successfully! The secret message is:"
  echo "\"$SECRET_MESSAGE\""
else
  echo "ERROR: Message verification failed!"
  exit 1
fi

# CHALLENGE PART 7: Working with descriptors to find the final treasure
echo ""
echo "CHALLENGE 7: The descriptor treasure map"
echo "-------------------------------------"
echo "The final treasure is locked with an address derived from a descriptor."
echo "Create a descriptor for your taproot address and derive the address to ensure it matches."

# Create a new taproot address
NEW_TAPROOT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" bech32m)
check_cmd "New taproot address generation"
NEW_TAPROOT_ADDR=$(trim "$NEW_TAPROOT_ADDR")

# Get the address info to extract the descriptor
# parent_desc (v30) is ranged tr(); descriptor (v28) may be specific
ADDR_INFO=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getaddressinfo "$NEW_TAPROOT_ADDR")
check_cmd "Getting address info"

# Get the descriptor — parent_desc in v30, descriptor in v28
DESCRIPTOR=$(echo "$ADDR_INFO" | jq -r '.parent_desc // .descriptor // empty')

# Extract the internal key from the descriptor
# Handle ranged: tr([fp/86h/1h/0h]key/0/*)#checksum
INTERNAL_KEY=$(echo "$DESCRIPTOR" | sed -n 's/.*tr(\(.*\))\/[^\/]*\*).*/\1/p')
# Fallback for non-ranged: tr([fp/86h/1h/0h]key/0/0)#checksum
if [ -z "$INTERNAL_KEY" ]; then
  INTERNAL_KEY=$(echo "$DESCRIPTOR" | sed -n 's/.*tr(\([^)]*\)).*/\1/p')
fi
check_cmd "Extracting key from descriptor"
INTERNAL_KEY=$(trim "$INTERNAL_KEY")

# Get the exact derivation index from the HD key path
INDEX=$(echo "$ADDR_INFO" | jq -r '.hdkeypath' | awk -F/ '{print $NF}')
echo "Using internal key: $INTERNAL_KEY at index $INDEX"

# Build a descriptor with the exact index
# If ranged, replace /* with the actual index; otherwise use as-is
if echo "$DESCRIPTOR" | grep -q '/\*'; then
  SIMPLE_DESCRIPTOR="tr($INTERNAL_KEY/0/$INDEX)"
else
  SIMPLE_DESCRIPTOR="tr($INTERNAL_KEY)"
fi
echo "Simple descriptor: $SIMPLE_DESCRIPTOR"

# Get a proper descriptor with checksum
TAPROOT_DESCRIPTOR=$(bitcoin-cli -regtest getdescriptorinfo "$SIMPLE_DESCRIPTOR" | jq -r '.descriptor')
check_cmd "Descriptor generation"
TAPROOT_DESCRIPTOR=$(trim "$TAPROOT_DESCRIPTOR")
echo "Taproot treasure map: $TAPROOT_DESCRIPTOR"

# Derive an address from the descriptor
DERIVED_ADDR_RAW=$(bitcoin-cli -regtest deriveaddresses "$TAPROOT_DESCRIPTOR")
check_cmd "Address derivation"
DERIVED_ADDR=$(echo "$DERIVED_ADDR_RAW" | tr -d '[]" \n\t')
echo "Derived quantum vault address: $DERIVED_ADDR"

# Verify the addresses match
echo "New taproot address: $NEW_TAPROOT_ADDR"
echo "Derived address:     $DERIVED_ADDR"

# Debug output to help diagnose any issues
echo "Address lengths: ${#NEW_TAPROOT_ADDR} vs ${#DERIVED_ADDR}"
echo "Address comparison (base64 encoded to see any hidden characters):"
echo "New:     $(echo -n "$NEW_TAPROOT_ADDR" | base64)"
echo "Derived: $(echo -n "$DERIVED_ADDR" | base64)"

if [[ "$NEW_TAPROOT_ADDR" == "$DERIVED_ADDR" ]]; then
  echo "Addresses match! The final treasure is yours!"
  
  # For educational purposes, show both addresses from the challenge
  echo ""
  echo "Note: In Bitcoin Core v28, the original taproot address used in the challenge was:"
  echo "Original address: $TAPROOT_ADDR"
  echo "This wasn't used in our final verification to ensure consistency with v28."
else
  echo "ERROR: Address mismatch detected! The derived address does not match the taproot address."
  echo "This indicates an issue with the descriptor derivation process."
  echo "New taproot address: $NEW_TAPROOT_ADDR"
  echo "Derived address:     $DERIVED_ADDR"
  exit 1
fi

# CHALLENGE COMPLETE
echo ""
echo "TREASURE HUNT COMPLETE!"
echo "======================="
show_wallet_info "btrustwallet"
echo ""
echo "Congratulations on completing the Bitcoin treasure hunt!"
echo "You've successfully used Bitcoin Core to:"
echo "- Create a wallet"
echo "- Generate different address types"
echo "- Track and verify balances"
echo "- Validate addresses"
echo "- Work with message signatures"
echo "- Use Bitcoin descriptors"
echo ""
echo "NOTE: This script is specifically designed to work with Bitcoin Core v28." 
