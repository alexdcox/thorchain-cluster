#!/bin/bash

. /docker/scripts/ready-poc-shared.sh

if [[ -n "$TARGET" ]]; then
  echo "Waiting for $TARGET..."
  wait_for_ready $ORCHESTRATOR $TARGET
fi

echo "Ready in $READY_AFTER seconds..."
sleep $READY_AFTER
send_ready $ORCHESTRATOR $(hostname)

echo "Ready!"
sleep infinity
