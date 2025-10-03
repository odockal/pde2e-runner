#!/bin/bash
set -e 

echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

# Install kubectl based on the arch
if [ $(uname -m) = arm64 ]; then
    URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/darwin/arm64/kubectl"
elif [ $(uname -m) = x86_64 ]; then
    URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/darwin/amd64/kubectl"
else
    echo "Unsupported architecture: $(uname -m)"
    exit 1
fi

echo "Downloading kubectl from $URL"
if [ -n "$GITHUB_TOKEN" ]; then
    curl -H "Authorization: Bearer $GITHUB_TOKEN" -L -o ./kubectl "$URL"
else
    echo "Warning: GITHUB_TOKEN is not set."
    curl -L -o ./kubectl "$URL"
fi

chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

kubectl version --client
echo "kubectl installation complete."
