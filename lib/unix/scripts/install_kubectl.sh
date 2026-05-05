#!/bin/bash
set -e

echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
# Install kubectl based on the arch
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
if [ $(uname -m) = arm64 ] || [ $(uname -m) = aarch64 ]; then
    curl -Lo ./kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${PLATFORM}/arm64/kubectl"
elif [ $(uname -m) = x86_64 ]; then
    curl -Lo ./kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${PLATFORM}/amd64/kubectl"
fi

chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

kubectl version --client
echo "kubectl installation complete."
