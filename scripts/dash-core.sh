#!/bin/bash

NODE_IP=$(ifconfig eth0 | grep 'inet' | awk '{print $2}')
SIGNER_NAME="${SIGNER_NAME:=thorchain}"
SIGNER_PASSWD="${SIGNER_PASSWD:=password}"
MASTER_ADDR="${DASH_MASTER_ADDR:=yWAMW2PfX6znBr9zxerJS6vp12nbPecKx6}"

initialBlocks=500

configPath="/dash/.dashcore/dash.conf"
logPath="/dash/.dashcore/dashd.log"

waitforverificationprogresscomplete() {
  echo "Waiting for node ($1) verification..."
  while true; do
    verificationprogress=$(dash-cli -rpcconnect=$1 getblockchaininfo 2>/dev/null | jq -r '.verificationprogress' 2>/dev/null)
    if [[ "$verificationprogress" == "1" ]]; then
      break
    fi
    sleep 1
  done
  echo "Dash node ready."
}

waitforpeerconnections() {
  echo "Waiting for node ($1) to establish $2 peer connections..."
    while true; do
    peers=$(dash-cli -rpcconnect=$1 getnetworkinfo | jq '.connections')
    if [[ "$peers" -ge "$2" ]]; then
      break
    fi
    sleep 1
  done
  echo "Node $1 has $2 peers."
}

waitforblock() {
  echo "Waiting for node ($1) to reach block $2..."
  while true; do
    block=$(dash-cli -rpcconnect=$1 getblockcount 2>/dev/null)
    if [[ "$block" -ge "$2" ]]; then
      break
    fi
    sleep 1
  done
  echo "Block $2 reached."
}

waitformasternodestatus() {
  echo "Waiting for masternode ($1) to reach $2 state..."
  while true; do
    mnstatus=$(dash-cli -rpcconnect=$1 masternode status 2>/dev/null)
    mnstate=$(echo $mnstatus | jq -r '.state' 2>/dev/null)
    # echo "$(date) Masternode status: [$mnstate] $(echo $mnstatus | jq -r '.status')"
    if [[ "$mnstate" == "$2" ]]; then
      break
    fi
    sleep 1
  done
  echo "Masternode ready."
}

waitformasternodesync() {
  echo "Waiting for masternode ($1) to reach MASTERNODE_SYNC_FINISHED state..."
  while true; do
    mnsyncstatus=$(dash-cli -rpcconnect=$1 mnsync status 2>&1 | jq -r '.AssetName' 2>&1)
    # echo "masternode sync status: $mnsyncstatus"
    if [[ $mnsyncstatus == "MASTERNODE_SYNC_FINISHED" ]]; then
      break
    fi
    sleep 1
  done
  echo "Masternode ready."
}

waitforquorumwithname() {
  echo "Waiting for quorum '$1' to be established..."
  while true; do
    count=$(dash-cli quorum list | jq ".$1 | length")
    if [[ "$count" -ge "2" ]]; then
      break
    fi
    sleep 1
  done
}

killpidandwait() {
  pid="$1"
  echo "Sending SIGTERM to process $1..."
  kill $pid
  while [[ $(
    ps -p $pid >/dev/null
    echo "$?"
  ) == "0" ]]; do
    sleep 0.2
  done
  echo "Process $1 terminated."
}

printthornodeconfig() {
  echo "
---------------- Thornode Configuration ----------------
NODE_IP                  $NODE_IP
SIGNER_NAME              $SIGNER_NAME
SIGNER_PASSWD            $SIGNER_PASSWD
MASTER_ADDR              $MASTER_ADDR
"
}

printmasternodeconfig() {
  echo "
--------------- Masternode Configuration ---------------
collateralAddress        $collateralAddress
collateralHash           $collateralHash
collateralVout           $collateralVout
ipPort                   $ipPort
ownerAddress             $ownerAddress
operatorPrivkey          $operatorPrivkey
operatorPubkey           $operatorPubkey
votingAddress            $votingAddress
operatorReward           $operatorReward
payoutAddress            $payoutAddress
feeSourceAddress         $feeSourceAddress
fundAddress              $fundAddress
"
}

writedashdconfig() {
  echo "Writing config file to: $configPath"
  tee "$configPath" >/dev/null <<EOF
regtest=1
[regtest]
  discover=0
  printtoconsole=1
  txindex=1
  debug=llmq
  rest=1
  server=1
  logips=1
  printpriority=1
  watchquorums=1
  allowprivatenet=1
  addressindex=1
  spentindex=1
  rpcuser=$SIGNER_NAME
  rpcpassword=$SIGNER_PASSWD
  rpcallowip=0.0.0.0/0
  bind=0.0.0.0:19899
  externalip=$NODE_IP
  rpcbind=0.0.0.0:19898
  rpcconnect=$NODE_IP:19898
  rpcport=19898
  sporkaddr=yUPxpYgEubT11whAthBorhnjiztcSJ35ze
  sporkkey=cUHWarE1SdgyVV5PBBq73sfD1fuXjDeXAAc2qjfUWZk9PHsyhPsQ
EOF
}

exitonsigterm() {
  timeToExit=0
  trap "timeToExit=1" SIGINT SIGTERM
  while true; do
    sleep 1
    if [[ ${timeToExit} == 1 ]]; then
      echo "Caught sigint/sigterm, exiting."
      if [[ "$dashpid" != "" ]]; then
        kill -9 $dashdpid
      fi
      kill -9 0
      exit 0
    fi
  done
}

startTime="$(date +%s)"
printtimetostart() {
  duration="$(($(date +%s) - startTime))"
  echo "Finished setting up the LLMQ in ${duration} seconds"
}
