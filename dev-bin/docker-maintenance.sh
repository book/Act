#! /bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

docker_override="$DIR"/docker-compose.override.yml
# Make sure the versions are correct
if [ -e $docker_override ]
then
    version=$(grep "^version:" $DIR/docker-compose.yml)
    version_override=$(grep "^version:" $docker_override)
    if [ "$version" != "$version_override" ]
    then
        echo "Setting $docker_override to $version";
        sed -i -e "s/^version:.*/$version/" $docker_override
    fi
fi

set -e

echo "Stopping and rebuilding containers"
docker-compose rm -f -s $@

# Regenerate configs so we don't mount files as directories
"$DIR"/dev-bin/generate-config.sh

docker-compose pull $@
docker-compose build --pull $@
docker-compose up --no-start $@
