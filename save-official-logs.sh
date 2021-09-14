#!/bin/zsh

logDir="./logs/official-$(date +%Y%m%d%H%M%S)"
mkdir $logDir && cd $_

containers=$(docker ps -a | tail -n +2 | awk '{print $1}')
images=$(docker ps -a | tail -n +2 | awk '{print $2}')

while IFS= read -r container; do
  image=$(docker inspect --format='{{.Config.Image}}' $container)
  cmd=$(docker inspect --format='{{.Config.Cmd}}' $container)

  name=$container

  if [[ $cmd == *"thornode"* ]]; then
    name="thornode"
  fi

  if [[ $cmd == *"bifrost"* ]]; then
    name="bifrost"
  fi

  if [[ $image == *"binance"* ]]; then
    name="binance"
  fi

  if [[ $image == *"litecoin"* ]]; then
    name="litecoin"
  fi

  if [[ $image == *"dogecoin"* ]]; then
    name="dogecoin"
  fi

  if [[ $image == *"bitcoin"* ]]; then
    name="bitcoin"
  fi

  if [[ $image == *"dash"* ]]; then
    name="dash"
  fi

  if [[ $image == *"timescale"* ]]; then
    name="timescale"
  fi

  if [[ $image == *"midgard"* ]]; then
    name="midgard"
  fi

  if [[ $image == *"ethereum"* ]]; then
    name="ethereum"
  fi

  echo "Writing $name.log..."
  docker logs $container >& "./$name.log"
done <<< "$containers"

#for container in "$containers"; do
#  echo "Writing $container.log..."
#  docker logs $container >& "./$container.log"
#done

echo "Copying /root/.thornode/config/config.toml..."
docker exec thornode cat /root/.thornode/config/config.toml >& thornode-config.toml

echo "Copying /root/.thornode/config/genesis.json..."
docker exec thornode cat /root/.thornode/config/genesis.json >& thornode-genesis.json

echo "Copying /etc/bifrost/config.json..."
docker exec bifrost cat /etc/bifrost/config.json >& bifrost-config.json

subl .


#docker logs thornode2 >& thornode2.log
#docker logs dash1 >& dash1.log
#docker logs dash1 >& dash1.log
#
## sed -i 's/\x1b\[[0-9;]*[a-zA-Z]//g' $logDir/thornode1.log
## cat $logDir/thornode1.log | perl -pe 's/\e\[[0-9;]*[a-zA-Z]//g' > $logDir/thornode1.log
#cat thornode1.log | sed -e 's/\[.*?m//g' > test.log
#cat thornode1.log | sed 's/\[.*?m//g' | sed 's/<0x1b>//g' > test.log
#
#docker logs thornode1 &>/dev/null
#docker logs thornode1 2>&1 3>&1 | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > $logDir/thornode1.log
#docker logs thornode2 > $logDir/thornode2.log
