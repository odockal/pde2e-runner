#!/bin/bash
set -e

echo "Installing minikube..."

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH="arm64" ;;
    x86_64)        ARCH="amd64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

URL="https://github.com/kubernetes/minikube/releases/latest/download/minikube-${PLATFORM}-${ARCH}"

echo "Downloading minikube from $URL"
if [ -n "$GITHUB_TOKEN" ]; then
    curl -H "Authorization: Bearer $GITHUB_TOKEN" -L -o ./minikube "$URL"
else
    echo "Warning: GITHUB_TOKEN is not set."
    curl -L -o ./minikube "$URL"
fi

sudo install minikube /usr/local/bin/minikube
minikube version
echo "minikube installation complete."
