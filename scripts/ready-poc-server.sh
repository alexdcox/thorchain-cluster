#!/bin/bash

. /docker/scripts/ready-poc-shared.sh

nodesReady=()

while true; do
#  if [[ $nodesReady -eq $NODES ]]; then
#    echo "All nodes ready, starting genesis..."
#    break
#  fi

  message=$(receive_message)
  # echo "Got message: '$message'"

  from=$(echo $message | awk '{print $1}')
  action=$(echo $message | awk '{print $2}')

  case $action in
  setup)
    echo "Setup $from"
    ;;

  setready)
    echo "Host $from ready."
    nodesReady+=($from)
    ;;

  checkready)
    checkHost=$(echo $message | awk '{print $3}')
    if [[ " ${nodesReady[*]} " =~ " ${checkHost} " ]]; then
      send_message $from 1
    else
      send_message $from 0
    fi
    ;;
  esac

done
