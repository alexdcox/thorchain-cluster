#!/bin/sh

set -o pipefail

. "$(dirname "$0")/core.sh"

SEEDS="${SEEDS:=none}"        # the hostname of multiple seeds set as tendermint seeds
PEER="${PEER:=none}"          # the hostname of a seed node set as tendermint persistent peer
PEER_API="${PEER_API:=$PEER}" # the hostname of a seed node API if different
SIGNER_NAME="${SIGNER_NAME:=thorchain}"
SIGNER_PASSWD="${SIGNER_PASSWD:=password}"
BINANCE=${BINANCE:=$PEER:26660}



#init_chain "$nodeAddress"
#thornode init local --chain-id thorchain


# add persistent peer tendermint config
#NODE_ID=$(fetch_node_id $PEER)
#peer_list "$NODE_ID" "$PEER"

# fetch_genesis_from_seeds $SEEDS

# add seeds tendermint config
#seeds_list $SEEDS


#(
#  # echo "Running setup commands in a bit just hold on alright?!"
#  # sleep 15
#
#  if [ "$NET" = "mocknet" ]; then
#    # create a binance wallet and bond/register
#    gen_bnb_address
#    ADDRESS=$(cat ~/.bond/address.txt)
#
#    # switch the BNB bond to native RUNE
#    "$(dirname "$0")/mock-switch.sh" $BINANCE "$ADDRESS" "$nodeAddress" $PEER
#
#     echo "wait for thorchain to register the new node account"
#     sleep 30
#    # wait_for_node_registration thornode1 $nodeAddress
#
#    # printf "%s\n" "$SIGNER_PASSWD" | thornode tx thorchain deposit 100000000000000 RUNE "bond:$nodeAddress" --node tcp://$PEER:26657 --from "$SIGNER_NAME" --keyring-backend=file --chain-id thorchain --yes
#
#    echo ""
#    echo "requesting bond from thornode1"
#    echo "$nodeAddress" | socat - TCP:thornode1:5060
#
#    # send bond
#
#    # echo ""
#    # echo "wait for thorchain to commit a block , otherwise it get the wrong sequence number"
#    wait_for_next_block localhost
#
#    NODE_PUB_KEY=$(echo "$SIGNER_PASSWD" | thornode keys show "$SIGNER_NAME" --pubkey --keyring-backend=file)
#    VALIDATOR=$(thornode tendermint show-validator)
#
#    echo ""
#    echo "set node keys"
#    # echo "thornode tx thorchain set-node-keys \"$NODE_PUB_KEY\" \"$NODE_PUB_KEY_ED25519\" \"$VALIDATOR\" --node tcp://localhost:26657 --from \"$SIGNER_NAME\" --keyring-backend=file --chain-id thorchain --yes;"
#
#    until printf "%s\n" "$SIGNER_PASSWD" | thornode tx thorchain set-node-keys \
#      "$NODE_PUB_KEY" \
#      "$NODE_PUB_KEY_ED25519" \
#      "$VALIDATOR" \
#      --node tcp://localhost:26657 \
#      --from "$SIGNER_NAME" \
#      --keyring-backend=file \
#      --chain-id thorchain \
#      --yes; do
#      sleep 5
#    done
#
##    echo ""
##    echo "wait for thorchain to commit a block"
##    wait_for_next_block localhost
#
#    echo ""
#    echo "add IP address"
#    # NODE_IP_ADDRESS=${EXTERNAL_IP:=$(curl -s http://whatismyip.akamai.com)}
#    NODE_IP_ADDRESS=$(ifconfig eth0 | grep 'inet' | awk '{print $2}' | sed 's/addr://')
#    until printf "%s\n" "$SIGNER_PASSWD" | thornode tx thorchain set-ip-address "$NODE_IP_ADDRESS" \
#      --node tcp://localhost:26657 \
#      --from "$SIGNER_NAME" \
#      --keyring-backend=file \
#      --chain-id thorchain \
#      --yes; do
#      sleep 5
#    done
#
##    echo ""
##    echo "wait for thorchain to commit a block"
##    wait_for_next_block localhost
#
#    echo "set node version"
#    until printf "%s\n" "$SIGNER_PASSWD" | thornode tx thorchain set-version \
#      --node tcp://localhost:26657 \
#      --from "$SIGNER_NAME" \
#      --keyring-backend=file \
#      --chain-id thorchain \
#      --yes; do
#      sleep 5
#    done
#
#  elif [ "$NET" = "testnet" ]; then
#    # create a binance wallet
#    gen_bnb_address
#    ADDRESS=$(cat ~/.bond/address.txt)
#  else
#    echo "Your THORNode address: $nodeAddress"
#    echo "Send your bond to that address"
#  fi
#
#)&

(
  create_thor_user "$SIGNER_NAME" "$SIGNER_PASSWD" "$SIGNER_SEED_PHRASE"
  thornode init local --chain-id thorchain

  nodeAddress=$(echo "$SIGNER_PASSWD" | thornode keys show "$SIGNER_NAME" -a --keyring-backend file)
  nodePubkey=$(echo "$SIGNER_PASSWD" | thornode keys show "$SIGNER_NAME" -p --keyring-backend file)
  validator=$(thornode tendermint show-validator)
  ed25519=$(echo "$SIGNER_PASSWD" | thornode ed25519)
  version=$(thornode version)
  ipAddress=$(determine_external_ip)

  until nc thornode1 5060; do
    echo "Waiting for thornode1 setup port to open..."
    sleep 1
  done

  send_startup_command thornode1 setup \
    $nodeAddress \
    $nodePubkey \
    $validator \
    $ed25519 \
    $version \
    $ipAddress
  send_startup_command thornode1 ready $nodeAddress

  fetch_genesis thornode1

  peer="thornode1"
  peerNodeId=$(fetch_node_id $peer)
  echo "Using peer '$peer' with nodeId $peerNodeId"
  peer_list "$peerNodeId" "$peer"

  peer_list thornode1

  enable_telemetry
  enable_internal_traffic
  external_address "$ipAddress" "$NET"

  (
    echo "Waiting for this things to get up and running..."

    until curl localhost:1317/node_info &>/dev/null ; do
      echo "waiting..."
      sleep 1
    done

    wait_for_next_block thornode2

    echo "Sending node deposit bond transaction..."
    echo "$SIGNER_PASSWD" | thornode tx thorchain deposit 120000000 RUNE "bond:$nodeAddress" \
      --from "$SIGNER_NAME" \
      --keyring-backend=file \
      --chain-id thorchain \
      --yes

#    echo "Setting node keys..."
#    echo "$SIGNER_PASSWD" | thornode tx thorchain set-node-keys \
#      $nodePubkey \
#      $ed25519 \
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

  (
    echo "$SIGNER_NAME"
    echo "$SIGNER_PASSWD"
  ) | exec "$@"
)&

exit_on_sigterm