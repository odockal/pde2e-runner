#!/bin/bash
set -e

echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    arm64|aarch64) ARCH="arm64" ;;
    x86_64)        ARCH="amd64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -Lo ./kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/${PLATFORM}/${ARCH}/kubectl"

chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

kubectl version --client
echo "kubectl installation complete."
