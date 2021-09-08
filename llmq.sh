#!/bin/zsh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

while true; do
  docker-compose -f $dir/llmq-compose.yaml -p dash up --remove-orphans -d
  echo -n "Press enter to EXIT and nuke dash nodes...";
  read ignored
  docker-compose -f $dir/llmq-compose.yaml -p dash down --volumes
  echo -n "Press enter to RESTART dash nodes...";
  read ignored
done


