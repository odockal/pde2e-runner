#!/bin/bash

# Versions variables
nodeVersion="v20.11.1"
gitVersion="2.42.0"

pdUrl=""
pdPath=""
targetFolder=""
resultsFolder="results"
fork="containers"
branch="main"
npmTarget="test:e2e:smoke"
podmanPath=""
initialize=0
start=0
rootful=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --pdUrl) pdUrl="$2"; shift ;;
        --pdPath) pdPath="$2"; shift ;;
        --targetFolder) targetFolder="$2"; shift ;;
        --resultsFolder) resultsFolder="$2"; shift ;;
        --fork) fork="$2"; shift ;;
        --branch) branch="$2"; shift ;;
        --npmTarget) npmTarget="$2"; shift ;;
        --podmanPath) podmanPath="$2"; shift ;;
        --initialize) initialize="$2"; shift ;;
        --start) start="$2"; shift ;;
        --rootful) rootful="$2"; shift ;;
        *) ;;
    esac
    shift
done

Download_PD() {
    echo "Downloading Podman Desktop from $pdUrl"
    curl -L "$pdUrl" -o pd.exe
}


echo "Podman desktop E2E runner script is being run..."

if [ -z "$targetFolder" ]; then
    echo "Error: targetFolder is required"
    exit 1
fi

echo "Switching to a target folder: $targetFolder"
cd "$targetFolder" || exit
echo "Create a resultsFolder in targetFolder: $resultsFolder"
mkdir -p "$resultsFolder"
workingDir=$(pwd)
echo "Working location: $workingDir"

# Specify the user profile directory
userProfile="$HOME"

# Specify the shared tools directory
toolsInstallDir="$userProfile/tools"

# Output file for built podman desktop binary
outputFile="pde2e-binary-path.log"

# Determine the system's arch
architecture=$(uname -m)

# Create the tools directory if it doesn't exist
if [ ! -d "$toolsInstallDir" ]; then
    mkdir -p "$toolsInstallDir"
fi

# node installation
if ! command -v node &> /dev/null; then
    if [ "$architecture" = "x86_64" ]; then
        nodeUrl="https://nodejs.org/download/release/$nodeVersion/node-$nodeVersion-darwin-x64.tar.xz"
    elif [ "$architecture" = "arm64" ]; then
        nodeUrl="https://nodejs.org/download/release/$nodeVersion/node-$nodeVersion-darwin-arm64.tar.xz"
    else
        echo "Error: Unsupported architecture $architecture"
        exit 1
    fi

    # Check if Node.js is already installed
    echo "$(ls $toolsInstallDir)"
    if [ ! -d "$toolsInstallDir/node-$nodeVersion-darwin-x64" ]; then
        # Download and install Node.js
        echo "Installing node $nodeVersion for $architecture architecture"
        echo "curl -O $nodeUrl | tar -xJ -C $toolsInstallDir"
        curl -o "$toolsInstallDir/node.tar.xz" "$nodeUrl" 
        tar -xf $toolsInstallDir/node.tar.xz -C $toolsInstallDir
    fi
    if [ -d "$toolsInstallDir/node-$nodeVersion-darwin-${architecture}/bin" ]; then
        echo "Node Installation path found"
        export PATH="$PATH:$toolsInstallDir/node-$nodeVersion-darwin-${architecture}/bin"
    else
        echo "Node installation path not found"
    fi
fi

# node and npm version check
echo "Node.js Version: $(node -v)"
echo "npm Version: $(npm -v)"

if ! command -v git &> /dev/null; then
    # Check if Git is already installed
    if [ ! -d "$toolsInstallDir/git-$gitVersion" ]; then
        # Download and install Git
        echo "Installing git $gitVersion"
        gitUrl="https://github.com/git/git/archive/refs/tags/v$gitVersion.tar.gz"
        mkdir -p "$toolsInstallDir/git-$gitVersion"
        curl -O "$gitUrl" | tar -xz -C "$toolsInstallDir/git-$gitVersion" --strip-components 1
        cd "$toolsInstallDir/git-$gitVersion" || exit
        make prefix="$toolsInstallDir/git-$gitVersion" all
        make prefix="$toolsInstallDir/git-$gitVersion" install
    fi
    export PATH="$PATH:$toolsInstallDir/git-$gitVersion/bin"
fi

# git verification
git --version

# Install Yarn
echo "Installing yarn"
npm install -g yarn
echo "Yarn Version: $(yarn --version)"

# Podman desktop binary
podmanDesktopBinary=""

if [ -z "$pdPath" ]; then
    if [ -n "$pdUrl" ]; then
        Download_PD
        podmanDesktopBinary="$workingDir/pd.exe"
    fi
else
    podmanDesktopBinary="$pdPath"
fi

# Setup Podman
if [ -n "$podmanPath" ] && ! command -v podman &> /dev/null; then
    echo "Podman is not installed..."
    echo "Settings podman binary location to PATH"
    export PATH="$PATH:$podmanPath"
else
    echo "Warning: Podman nor Podman Path is specified!"
    # exit 1;
fi

# Configure Podman Machine
if (( initialize == 1 )); then
    flags=""
    if (( rootful == 1 )); then
        flags+="--rootful "
    fi
    flags=$(echo "$flags" | awk '{$1=$1};1')
    flagsArray=($flags)
    echo "Initializing podman machine, command: podman machine init $flags"
    logFile="$workingDir/$resultsFolder/podman-machine-init.log"
    echo "podman machine init $flags" > "$logFile"
    if (( ${#flagsArray[@]} > 0 )); then
        podman machine init "${flagsArray[@]}" 2>&1 | tee -a "$logFile"
    else
        podman machine init 2>&1 | tee -a "$logFile"
    fi
    if (( start == 1 )); then
        echo "Starting podman machine..."
        echo "podman machine start" >> "$logFile"
        podman machine start 2>&1 | tee -a "$logFile"
    fi
    podman machine ls 2>&1 | tee -a "$logFile"
fi

# Checkout Podman Desktop if it does not exist
echo "Working Dir: $workingDir"
if [ -d "podman-desktop" ]; then
    echo "podman-desktop github repo exists"
else
    repositoryURL="https://github.com/$fork/podman-desktop.git"
    echo "Checking out $repositoryURL"
    git clone "$repositoryURL"
fi

cd "podman-desktop" || exit
echo "Fetching all branches and tags"
git fetch --all
echo "Checking out branch: $branch"
git checkout "$branch"

if [ -n "$podmanDesktopBinary" ]; then
    export PODMAN_DESKTOP_BINARY="$podmanDesktopBinary"
fi

export CI=true
testsOutputLog="$workingDir/$resultsFolder/tests.log"
echo "Installing dependencies storing yarn run output in: $testsOutputLog"
yarn install 2>&1 | tee -a $testsOutputLog
echo "Running the e2e playwright tests using target: $npmTarget, binary used: $podmanDesktopBinary"
yarn "$npmTarget" 2>&1 | tee -a $testsOutputLog

echo "Collecting the results into: $workingDir/$resultsFolder/"
cp -r "$workingDir/podman-desktop/tests/output/"* "$workingDir/$resultsFolder/"

echo "Script finished..."
