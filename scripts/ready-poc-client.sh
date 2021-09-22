#!/bin/bash

. /docker/scripts/orchestrator.sh

#if [[ -n "$TARGET" ]]; then
#  echo "Waiting for $TARGET..."
#  orchestrator_wait_for_ready $ORCHESTRATOR $TARGET
#fi

echo "Ready in 4 seconds..."
sleep 4
orchestrator_send_ready

echo "Ready!"
