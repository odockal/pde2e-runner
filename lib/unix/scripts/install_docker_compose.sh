#!/bin/bash
set -e

echo "Installing docker-compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH="aarch64" ;;
    x86_64)        ARCH="x86_64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

URL="https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${PLATFORM}-${ARCH}"

echo "Downloading docker-compose from $URL"
if [ -n "$GITHUB_TOKEN" ]; then
    curl -H "Authorization: Bearer $GITHUB_TOKEN" -L -o ./docker-compose "$URL"
else
    echo "Warning: GITHUB_TOKEN is not set."
    curl -L -o ./docker-compose "$URL"
fi

chmod +x ./docker-compose
sudo mv ./docker-compose /usr/local/bin/docker-compose

docker-compose --version
echo "docker-compose installation complete."
