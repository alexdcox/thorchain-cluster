#!/bin/bash

BLOCK_TIME=${BLOCK_TIME:=5}

. /docker/scripts/orchestrator.sh
. /docker/scripts/dash-core.sh

verifyinstantsendandchainlocks() {
  echo "Verifying instantsend and chainlock..."
  newaddress=$(dash-cli getnewaddress)
  hash=$(dash-cli sendtoaddress $newaddress 10)
  sleep $BLOCK_TIME
  rawtx=$(dash-cli getrawtransaction $hash true)
  echo "--> tx hash: $hash"
  instantlock=$(echo "$rawtx" | jq '.instantlock')
  chainlock=$(echo "$rawtx" | jq '.chainlock')
  if [[ "$instantlock" == "true" ]]; then
    echo "--> instantlock OK"
  else
    echo "--> instantlock FAILED"
    sleep infinity
  fi
  if [[ "$chainlock" == "true" ]]; then
    echo "--> chainlock OK"
  else
    echo "--> chainlock FAILED"
    sleep infinity
  fi
}

genesis() {
  printthornodeconfig
  echo "BLOCK_TIME               $BLOCK_TIME"

  writedashdconfig

  dashd 1>$logPath &
  dashdpid="$!"

  waitforverificationprogresscomplete $(hostname)

  while true; do
    nextBlockHash="$(dash-cli generate 1 &> /dev/null | jq -r '.[0]')"
    sleep $BLOCK_TIME
  done &

  echo "Generating $initialBlocks initial blocks..."
  dash-cli generate $initialBlocks &> /dev/null

  waitforblock $(hostname) $initialBlocks

  waitforblock dash2 $initialBlocks
  waitformasternodestatus dash2 READY
  waitformasternodesync dash2

  waitforblock dash3 $initialBlocks
  waitformasternodestatus dash3 READY
  waitformasternodesync dash3

  waitforblock dash4 $initialBlocks
  waitformasternodestatus dash4 READY
  waitformasternodesync dash4

  waitforpeerconnections $(hostname) 3

  echo "Activating sporks..."
  # dash-cli spork SPORK_2_INSTANTSEND_ENABLED 0
  # dash-cli spork SPORK_3_INSTANTSEND_BLOCK_FILTERING 0
  dash-cli spork SPORK_9_SUPERBLOCKS_ENABLED 0 &> /dev/null
  dash-cli spork SPORK_17_QUORUM_DKG_ENABLED 0 &> /dev/null
  dash-cli spork SPORK_19_CHAINLOCKS_ENABLED 0 &> /dev/null
  # dash-cli spork SPORK_21_QUORUM_ALL_CONNECTED 1

  while true; do
    dash-cli generate 1 &> /dev/null
    count=$(dash-cli quorum list | jq ".llmq_test | length")
    if [[ "$count" -ge "2" ]]; then
      break
    fi
    sleep 0.1
  done &

  waitforquorumwithname llmq_test
  printtimetostart
  orchestrator_send_ready

  sleep $BLOCK_TIME
  verifyinstantsendandchainlocks
  sleep 8

  echo "Following dashd log from start:"

  tail -f -n +1 $logPath
}

genesis &
exitonsigterm
