#!/bin/zsh

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

thornodeImageInfo=$(docker image list | grep github.com/alexdcox/thornode | grep mocknet)
if [[ -z $thornodeImageInfo ]]; then
  echo "The custom image 'github.com/alexdcox/thornode:mocknet' was not found, exiting."
  exit 1
fi

dashImageInfo=$(docker image list | grep github.com/alexdcox/dash | grep latest)
if [[ -z $dashImageInfo ]]; then
  echo "The custom image 'github.com/alexdcox/dash:latest' was not found, exiting."
  exit 1
fi

#build() {
#  cd build/docker
#  docker build --build-arg TAG=mocknet -t github.com/alexdcox/thornode -f Dockerfile ../..
#  cd -
#}

shutdown() {
  echo "Caught SIGINT, shutting down everything..."
  docker-compose -p thorchain -f $dir/docker/docker-compose.yaml down --volumes
  exit "$?"
}

while true; do
  docker-compose -p thorchain -f $dir/docker/docker-compose.yaml up --remove-orphans -d
  echo -n "Press enter to STOP thorchain..."
  read ignored
  docker-compose -p thorchain -f $dir/docker/docker-compose.yaml down --volumes
  echo -n "Press enter to RESTART thorchain..."
  read ignored
done
