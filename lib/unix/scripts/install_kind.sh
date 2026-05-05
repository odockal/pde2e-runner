#!/bin/bash
set -e

echo "Installing kind..."
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)
# Install kind based on the arch
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ $(uname -m) = arm64 ] || [ $(uname -m) = aarch64 ]; then
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${PLATFORM}-arm64"
elif [ $(uname -m) = x86_64 ]; then
    curl -Lo ./kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-${PLATFORM}-amd64"
else
    echo "Unsupported architecture: $(uname -m)"
    exit 1
fi

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind version
echo "kind installation complete."
