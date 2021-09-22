#!/bin/bash

. /docker/scripts/orchestrator.sh

set -o pipefail

. "$(dirname "$0")/core.sh"
. "$(dirname "$0")/orchestrator.sh"
. "$(dirname "$0")/testnet-state.sh"

SIGNER_NAME="${SIGNER_NAME:=thorchain}"
SIGNER_PASSWD="${SIGNER_PASSWD:=password}"
NODES="${NODES:=1}"
#SEED="${SEED:=thornode}" # the hostname of the master node
#ETH_HOST="${ETH_HOST:=http://ethereum-localnet:8545}"
THOR_BLOCK_TIME="${THOR_BLOCK_TIME:=5s}"
VAULT_MNEMONIC="${VAULT_SIGNER_PASSWD:=rude assume tourist hammer choice remain move work ski faith actual walnut license sign guilt gallery nature key duck host ecology juice club scissors}"
VAULT_SIGNER_PASSWD="${SIGNER_PASSWD:=password}"

#VALIDATOR=$(thornode tendermint show-validator)
#NODE_ADDRESS=$(echo "$SIGNER_PASSWD" | thornode keys show $SIGNER_NAME -a --keyring-backend file)
#NODE_PUB_KEY=$(echo "$SIGNER_PASSWD" | thornode keys show $SIGNER_NAME -p --keyring-backend file)
#VERSION=$(fetch_version)

#mkdir -p /tmp/shared

#if [ "$SEED" = "$(hostname)" ]; then
#  thornode tendermint show-node-id >/tmp/shared/node.txt
#fi

# write node account data to json file in shared directory
#echo "$NODE_ADDRESS $VALIDATOR $NODE_PUB_KEY $VERSION $NODE_ADDRESS $NODE_PUB_KEY_ED25519" >"/tmp/shared/node_$NODE_ADDRESS.json"

# wait until THORNode have the correct number of nodes in our directory before continuing
#while [ "$(find /tmp/shared -maxdepth 1 -type f -name 'node_*.json' | awk -F/ '{print $NF}' | wc -l | tr -d '[:space:]')" != "$NODES" ]; do
#  sleep 1
#done

# deploy eth contract
# deploy_eth_contract $ETH_HOST

# override block time for faster smoke tests

#if [ "$SEED" = "$(hostname)" ]; then
#  if [ ! -f ~/.thornode/config/genesis.json ]; then
#    # get a list of addresses (thor bech32)
#    ADDRS=""
#    for f in /tmp/shared/node_*.json; do
#      ADDRS="$ADDRS,$(awk <"$f" '{print $1}')"
#    done
#
#    if [ -n "${VAULT_PUBKEY+x}" ]; then
#      PUBKEYS=""
#      for f in /tmp/shared/node_*.json; do
#        PUBKEYS="$PUBKEYS,$(awk <"$f" '{print $3}')"
#      done
#      add_vault "$VAULT_PUBKEY" "$(echo "$PUBKEYS" | sed -e 's/^,*//')"
#    fi

# NODE_IP_ADDRESS=${EXTERNAL_IP:=$(curl -s http://whatismyip.akamai.com)}
#    NODE_IP_ADDRESS=$(determine_external_ip)

# add node accounts to genesis file
#    for f in /tmp/shared/node_*.json; do
#      if [ -n "${VAULT_PUBKEY+x}" ]; then
#        add_node_account "$(awk <"$f" '{print $1}')" "$(awk <"$f" '{print $2}')" "$(awk <"$f" '{print $3}')" "$(awk <"$f" '{print $4}')" "$(awk <"$f" '{print $5}')" "$(awk <"$f" '{print $6}')" "$NODE_IP_ADDRESS" "$VAULT_PUBKEY"
#      else
#        add_node_account "$(awk <"$f" '{print $1}')" "$(awk <"$f" '{print $2}')" "$(awk <"$f" '{print $3}')" "$(awk <"$f" '{print $4}')" "$(awk <"$f" '{print $5}')" "$(awk <"$f" '{print $6}')" "$NODE_IP_ADDRESS"
#      fi
#    done

# setup peer connection
# This is confusing, why cant we just have a peer shell script? keep things separate and easily digestible.
#if [ "$SEED" != "$(hostname)" ]; then
#  if [ ! -f ~/.thornode/config/genesis.json ]; then
#    echo "Setting THORNode as peer not genesis"
#
#    init_chain "$NODE_ADDRESS"
#    fetch_genesis $SEED
#    echo "NODE ID: $NODE_ID"
#    NODE_ID=$(fetch_node_id $SEED)
#    peer_list "$NODE_ID" "$SEED"
#
#    cat ~/.thornode/config/genesis.json
#  fi
#fi

#echo "Listening on port 5060 for bond requests..."
#(while true; do
#  sendBondToAddress=$(socat - TCP-LISTEN:5060,crlf,reuseaddr)
#  if [[ "$sendBondToAddress" != "" ]]; then
#    echo "Send bond to address $sendBondToAddress"
#    echo "$SIGNER_PASSWD" | thornode tx thorchain deposit 500000000 RUNE "bond:$sendBondToAddress" \
#      --from $SIGNER_NAME \
#      --keyring-backend=file \
#      --chain-id thorchain \
#      --yes
#  fi
#done)&

(
  echo "Setting THORNode as genesis"

  # this is required as it need to run thornode init , otherwise tendermint related commant doesn't work
  init_chain
  rm -rf ~/.thornode/config/genesis.json

  # create_thor_user "$SIGNER_NAME" "$SIGNER_PASSWD" "$SIGNER_SEED_PHRASE"
  echo "Creating Thornode genesis user '$SIGNER_NAME'"
  printf "%s\n%s\n%s\n" "$SIGNER_SEED_PHRASE" "$SIGNER_PASSWD" "$SIGNER_PASSWD" | thornode keys --keyring-backend file add "$SIGNER_NAME" --recover
  NODE_PUB_KEY_ED25519=$(printf "%s\n%s\n" "$SIGNER_PASSWD" "$SIGNER_SEED_PHRASE" | thornode ed25519)

  thornode init local --chain-id thorchain

  nodesReady=0
  vaultPubkeys=""
  echo "Listening on port 5060 for startup requests, will continue when $NODES thornode(s) are ready..."
  while true; do
    if [[ $nodesReady -eq $NODES ]]; then
      echo "All nodes ready, starting genesis..."
      break
    fi

    message=$(socat - TCP-LISTEN:5060,crlf,reuseaddr)
    #    echo "Got message: '$message'"
    action=$(echo $message | awk '{print $1}')
    #    echo "$action"
    case $action in
    setup)
      nodeAddress=$(echo $message | awk '{print $2}')
      nodePubkey=$(echo $message | awk '{print $3}')
      validator=$(echo $message | awk '{print $4}')
      nodeEd25519=$(echo $message | awk '{print $5}')
      version=$(echo $message | awk '{print $6}')
      ipAddress=$(echo $message | awk '{print $7}')

      echo "Adding genesis account for node '$nodeAddress'"
      thornode add-genesis-account "$nodeAddress" 1000000000000000000rune

      echo "Adding node_account for node '$nodeAddress'"
      bondAddress=$nodeAddress
      add_node_account \
        $nodeAddress \
        $validator \
        $nodePubkey \
        $version \
        $bondAddress \
        $nodeEd25519 \
        $ipAddress

      # Does 'access' communicate the right idea?
      echo "Configuring node pubkey for vault access"
      vaultPubkeys="$vaultPubkeys;$nodePubkey"
      ;;

    ready)
      nodeAddress=$(echo $message | awk '{print $2}')
      echo "Node '$nodeAddress' setup complete."
      nodesReady=$(($nodesReady + 1))
      echo "$nodesReady/$NODES nodes are ready."
      ;;

    esac
  done

  #init_chain "$(echo "$ADDRS" | sed -e 's/^,*//')"

  echo "Setting up accounts..."
  add_account tthor1z63f3mzwv3g75az80xwmhrawdqcjpaekk0kd54 rune 5000000000000
  add_account tthor1wz78qmrkplrdhy37tw0tnvn0tkm5pqd6zdp257 rune 25000000000100
  add_account tthor1xwusttz86hqfuk5z7amcgqsg7vp6g8zhsp5lu2 rune 5090000000000
  add_account tthor1xfkj2ukuvmwgrdlv74cu6v2ungs0ls69km7x6n rune 5090000000000
  # add_account tthor1zzja0wl7etldc4caprkfjwd74k68qqvfl32tj5 rune 6666666666666

  reserve 22000000000000000

  nodeAddress=$(echo "$SIGNER_PASSWD" | thornode keys show "$SIGNER_NAME" -a --keyring-backend file)
  nodePubkey=$(echo "$SIGNER_PASSWD" | thornode keys show "$SIGNER_NAME" -p --keyring-backend file)
  nodeEd25519=$(echo "$SIGNER_PASSWD" | thornode ed25519)
  validator=$(thornode tendermint show-validator)
  version=$(thornode version)
  ipAddress=$(determine_external_ip)
  bondAddress=$nodeAddress

  echo "Adding genesis account for '$nodeAddress'"
  thornode add-genesis-account $nodeAddress 1000000000000000rune

  add_node_account \
    $nodeAddress \
    $validator \
    $nodePubkey \
    $version \
    $bondAddress \
    $nodeEd25519 \
    $ipAddress

  # create_thor_user "$SIGNER_NAME" "$SIGNER_PASSWD" "$SIGNER_SEED_PHRASE"
#  printf "%s\n%s\n%s\n" "$VAULT_MNEMONIC" "$VAULT_SIGNER_PASSWD" "$VAULT_SIGNER_PASSWD" | thornode keys add thorchain \
#    --keyring-backend file \
#    --recover

  # vaultPubkey=$nodePubkey
  # add_vault $vaultPubkey "$vaultPubkeys"

  vaultPubkey=$(echo "$VAULT_SIGNER_PASSWD" | thornode keys show thorchain -p --keyring-backend file)
  vaultPubkeys="$vaultPubkeys;$nodePubkey"
  vaultPubkeys=$(echo $vaultPubkeys | sed -e 's/^;//')
  echo "Adding vault '$vaultPubkey' with keys '$vaultPubkeys'..."
  add_vault $vaultPubkey $vaultPubkeys

  block_time "$THOR_BLOCK_TIME"
  disable_bank_send
  enable_telemetry
  enable_internal_traffic

  external_address "$(determine_external_ip)" "$NET"

#  echo "Adding default pools"
#  cat ~/.thornode/config/genesis.json | jq ".app_state.thorchain.pools |= . + $(cat /docker/scripts/genesis-pool.json)" > /tmp/genesis.json
#  mv /tmp/genesis.json ~/.thornode/config/genesis.json

  echo "Genesis content"
  cat ~/.thornode/config/genesis.json
  thornode validate-genesis --trace
  if [[ "$?" != 0 ]]; then
    sleep infinity
  fi

  (
    echo "Waiting for this things to get up and running..."

    until curl -s localhost:1317/node_info 2>&1 >/dev/null; do
      sleep 1
    done

    wait_for_block thornode1 2

    echo "Sending node bond transaction..."
    echo "$SIGNER_PASSWD" | thornode tx thorchain deposit 120000000 RUNE "bond:$nodeAddress" \
      --from "$SIGNER_NAME" \
      --keyring-backend=file \
      --chain-id thorchain \
      --yes

#    echo "Setting node keys..."
#    echo "$SIGNER_PASSWD" | thornode tx thorchain set-node-keys \
#      $nodePubkey \
#      $nodeEd25519 \
#      $validator \
#      --node tcp://localhost:26657 \
#      --from "$SIGNER_NAME" \
#      --keyring-backend file \
#      --chain-id thorchain \
#      --yes

    echo "Setting node ip address..."
    echo "$SIGNER_PASSWD" | thornode tx thorchain set-ip-address $ipAddress \
      --node tcp://localhost:26657 \
      --from "$SIGNER_NAME" \
      --keyring-backend file \
      --chain-id thorchain \
      --yes

    echo "Setting node version..."
    echo "$SIGNER_PASSWD" | thornode tx thorchain set-version \
      --node tcp://localhost:26657 \
      --from "$SIGNER_NAME" \
      --keyring-backend file \
      --chain-id thorchain \
      --yes

  )&

  printf "%s\n%s\n" "$SIGNER_NAME" "$SIGNER_PASSWD" | exec "$@"
  echo "Something went badly wrong, genesis node has exited with code '$?'"
) &

exit_on_sigterm
