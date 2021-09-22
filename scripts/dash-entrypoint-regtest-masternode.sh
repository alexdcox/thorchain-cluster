#!/bin/bash

. /docker/scripts/orchestrator.sh
. /docker/scripts/dash-core.sh

masternode() {
  printthornodeconfig
  writedashdconfig

  waitforblock dash1 $initialBlocks

  dashd -addnode=dash1 1>$logPath &
  dashdpid="$!"

  waitforblock $(hostname) $initialBlocks

  ownerAddress=$(dash-cli getnewaddress)
  collateralAddress=$(dash-cli getnewaddress)
  collateralVout=1
  ipPort="$NODE_IP:19899"
  votingAddress=$(dash-cli getnewaddress)
  operatorBls=$(dash-cli bls generate)
  operatorPrivkey=$(echo $operatorBls | jq -r '.secret')
  operatorPubkey=$(echo $operatorBls | jq -r '.public')
  operatorReward=0
  payoutAddress=$(dash-cli getnewaddress)
  feeSourceAddress=$ownerAddress
  fundAddress=$(dash-cli getnewaddress)

  echo "Sending 1001 DASH to masternode fund address $fundAddress"
  fundHash=$(dash-cli -rpcconnect=dash1 sendtoaddress $fundAddress 1001 2>&1)
  if [[ "$fundHash" == *"error code"* ]]; then
    echo "Fund transaction failed: $fundHash"
    sleep infinity
  else
    echo "Fund tx hash: $fundHash"
  fi

  echo "Sending 1001 DASH to masternode collateral address $collateralAddress"
  collateralHash=$(dash-cli -rpcconnect=dash1 sendtoaddress $collateralAddress 1001 2>&1)
  if [[ "$collateralHash" == *"error code"* ]]; then
    echo "Collateral transaction failed: $collateralHash"
    sleep infinity
  else
    echo "Collateral tx hash: $collateralHash"
  fi

  echo "Generating confirmation blocks..."
  dash-cli -rpcconnect=dash1 generate 20

  echo "Balance of fund address"
  dash-cli getaddressbalance \"$fundAddress\"

  echo "Balance of collateral address"
  dash-cli getaddressbalance \"$collateralAddress\"

  echo "Current addresses and balances:"
  dash-cli listaddressgroupings

  printmasternodeconfig

  echo "Sending protx register command"
  registerHash=$(dash-cli protx register_fund \
    $collateralAddress \
    $ipPort \
    $ownerAddress \
    $operatorPubkey \
    $votingAddress \
    $operatorReward \
    $payoutAddress \
    $fundAddress)

  echo "Protx registration tx hash: $registerHash"

  if [[ "$registerHash" == "" ]]; then
    echo "Protx register failed."
    sleep infinity
  fi

  while true; do
    output=$(dash-cli -rpcconnect=dash1 getrawtransaction $registerHash true 2>&1)
    if [[ "$output" == *"No such mempool or blockchain transaction."* || "$output" == *"error code"* ]]; then
      echo "Protx not accepted by genesis node, re-sending..."
      rawtx=$(dash-cli getrawtransaction $registerHash 2>&1)
      dash-cli sendrawtransaction $rawtx &> /dev/null
      sleep 1
    else
      echo "Protx accepted by genesis node!"
      break
    fi
  done

  echo "Setting masternode operator bls key in dash.conf"
  echo "  masternodeblsprivkey=$operatorPrivkey" >>$configPath

  echo "Restarting dashd to initiate masternode sync"
  killpidandwait $dashdpid
  sleep 2
  dashd -connect=dash1 1>$logPath &
  dashdpid="$!"

  echo "Started new dashd process $dashdpid"
  waitforverificationprogresscomplete $(hostname)
  waitformasternodestatus $(hostname) READY
  waitformasternodesync $(hostname)

  echo "Adding other masternode peers..."
  dash-cli addnode dash2 add
  dash-cli addnode dash3 add
  dash-cli addnode dash4 add
  waitforpeerconnections $(hostname) 3

  waitforquorumwithname llmq_test

  printtimetostart

  echo "Following dashd log from start:"
  tail -f -n +1 $logPath
}

masternode &
exitonsigterm
