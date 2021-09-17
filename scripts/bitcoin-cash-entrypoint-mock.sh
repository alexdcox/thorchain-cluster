#!/bin/sh

# . /docker/scripts/core.sh

waitforblock() {
  echo "Waiting for node ($1) to reach block $2..."
  while true; do
    block=$(bitcoin-cli -rpcconnect=$1 getblockcount 2>/dev/null)
    if [[ "$block" -ge "$2" ]]; then
      break
    fi
    sleep 1
  done
  echo "Block $2 reached."
}

SIGNER_NAME="${SIGNER_NAME:=thorchain}"
SIGNER_PASSWD="${SIGNER_PASSWD:=password}"
MASTER_ADDR="${BTC_MASTER_ADDR:=bchreg:qzfuujzhpd2ugtp2lqt2a2aqdnlwzgj04cwqq36m3u}"
BLOCK_TIME=${BLOCK_TIME:=1}
RPC_PORT=${RPC_PORT:=18443}

configDir="/root/.bitcoin"
configPath="$configDir/bitcoin.conf"

echo "Writing config file to: $configPath"
mkdir -p $configDir
tee "$configPath" <<EOF
regtest=1
[regtest]
  txindex=1
  rpcuser=$SIGNER_NAME
  rpcpassword=$SIGNER_PASSWD
  rpcallowip=0.0.0.0/0
  rpcbind=0.0.0.0:$RPC_PORT
  rpcport=$RPC_PORT
EOF

bitcoind &

if [[ $(hostname) == "bitcoincash1" ]]; then
  echo "Adding node bitcoincash2"
  bitcoin-cli addnode bitcoincash2 add

  while true
  do
    bitcoin-cli generatetoaddress 100 $MASTER_ADDR && break
    sleep 5
  done

  # mine a new block every BLOCK_TIME
  while true
  do
    bitcoin-cli generatetoaddress 1 $MASTER_ADDR
    sleep $BLOCK_TIME
  done
else
  waitforblock bitcoincash1 1
  echo "Adding node bitcoincash1"
  bitcoin-cli addnode bitcoincash1 add
fi

sleep infinity