#!/bin/bash
echo "Installing minikube..."

if [ $(uname -m) = arm64 ]; then
    curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-arm64
    sudo install minikube-darwin-arm64 /usr/local/bin/minikube
elif [ $(uname -m) = x86_64 ]; then
    curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-darwin-amd64
    sudo install minikube-darwin-amd64 /usr/local/bin/minikube  
fi

minikube version
echo "minikube installation complete."
