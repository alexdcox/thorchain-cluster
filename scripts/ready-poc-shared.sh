#!/bin/bash

send_message() {
  from=$(hostname)
  to=$1
  action=$2
  shift
  # echo "Sending $from -> $to | $@..."
  # echo "$from $@"
  until echo "$from $@" | socat - TCP:$to:5060,connect-timeout=5 2>/dev/null; do
    sleep 1;
  done
}

receive_message() {
  socat - TCP-LISTEN:5060,crlf,reuseaddr
}

wait_for_ready() {
  orchestrator=$1
  host=$2
  echo "Waiting for orchestrator '$orchestrator' to report host '$host' ready..."
  while true; do
    send_message $orchestrator checkready $host
    response=$(receive_message)
    ready=$(echo $response | awk '{print $2}')
    # echo "Got ready response '$ready'"
    if [[ "$ready" == "1" ]]; then
      # echo "We're done here"
      break
    fi
    sleep 1
  done
}

send_ready() {
  orchestrator=$1
  echo "Sending ready ($(hostname)) to '$orchestrator'..."
  send_message $orchestrator setready
}
