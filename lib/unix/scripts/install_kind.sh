#!/bin/bash
set -e

echo "Installing kind..."
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH="arm64" ;;
    x86_64)        ARCH="amd64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${PLATFORM}-${ARCH}"

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind version
echo "kind installation complete."
