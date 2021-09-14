#!/bin/zsh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

logDir="./logs/unofficial-$(date +%Y%m%d%H%M%S)"
mkdir $logDir
cd $logDir

containers=("thornode1" "bifrost1" "thornode2" "dash1" "dash2" "dash3" "dash4" "bitcoin1" "binance1")

for container in ${containers[@]}; do
  echo "Writing $container.log..."
  docker logs $container >& "./$container.log"
done

echo "Copying /root/.thornode/config/config.toml..."
docker exec thornode1 cat /root/.thornode/config/config.toml >& thornode-config.toml

echo "Copying /root/.thornode/config/genesis.json..."
docker exec thornode1 cat /root/.thornode/config/genesis.json >& thornode-genesis.json

echo "Copying /etc/bifrost/config.json..."
docker exec bifrost1 cat /etc/bifrost/config.json >& bifrost-config.json

echo "Copying docker-compose.yaml..."
cp $dir/docker/docker-compose.yaml .

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
