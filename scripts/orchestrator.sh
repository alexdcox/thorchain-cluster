#!/bin/bash

orchestrator_send_message() {
  from=$(hostname)
  to=$1
  action=$2
  shift
  echo "Sending $from -> $to | $@..."
  # echo "$from $@"
  until echo "$from $@" | socat - TCP:$to:5070,connect-timeout=5; do
    sleep 1;
  done
}

orchestrator_receive_message() {
  socat - TCP-LISTEN:5070,crlf,reuseaddr
}

orchestrator_wait_for_ready() {
  host=$1
  echo "[orchestrator] Waiting for '$ORCHESTRATOR_HOST' to report host '$host' ready..."
  while true; do
    orchestrator_send_message $ORCHESTRATOR_HOST checkready $host
    response=$(orchestrator_receive_message)
    ready=$(echo $response | awk '{print $2}')
    # echo "Got ready response '$ready'"
    if [[ "$ready" == "1" ]]; then
      # echo "We're done here"
      break
    fi
    sleep 1
  done
}

orchestrator_send_ready() {
  echo "[orchestrator] Sending '$(hostname)' ready to '$ORCHESTRATOR_HOST'..."
  orchestrator_send_message $ORCHESTRATOR_HOST setready
}

orchestrator_start() {
  echo "[orchestrator] running on port 5070."

  hostsReady=()

  while true; do
    message=$(orchestrator_receive_message)
    # echo "Got message: '$message'"
    from=$(echo $message | awk '{print $1}')
    action=$(echo $message | awk '{print $2}')

    case $action in
    exit)
      echo "[orchestrator] received exit signal."
      break
      ;;

    setready)
      echo "[orchestrator] Host '$from' ready."
      hostsReady+=($from)
      ;;

    checkready)
      checkHost=$(echo $message | awk '{print $3}')
      if [[ " ${hostsReady[*]} " =~ " ${checkHost} " ]]; then
        orchestrator_send_message $from 1
      else
        orchestrator_send_message $from 0
      fi
      ;;
    esac
  done
}

if [[ "$ORCHESTRATOR_HOST" == "$(hostname)" ]]; then
  orchestrator_start &
fi

if [[ $ORCHESTRATOR_WAIT_FOR_HOST ]]; then
 orchestrator_wait_for_ready $ORCHESTRATOR_WAIT_FOR_HOST
fi