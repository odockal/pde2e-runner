#!/bin/bash
set -e 

echo "Installing kind..."
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)

# Install kind based on the arch
if [ $(uname -m) = arm64 ]; then
    URL="https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-darwin-arm64"
elif [ $(uname -m) = x86_64 ]; then
    URL="https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-darwin-amd64" 
else
    echo "Unsupported architecture: $(uname -m)"
    exit 1
fi

echo "Downloading kind from $URL"
if [ -n "$GITHUB_TOKEN" ]; then
    curl -H "Authorization: Bearer $GITHUB_TOKEN" -L -o ./kind "$URL"
else
    echo "Warning: GITHUB_TOKEN is not set."
    curl -L -o ./kind "$URL"
fi

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

kind version
echo "kind installation complete."
