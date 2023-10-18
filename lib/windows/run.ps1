param(
    [Parameter(HelpMessage='url to download the exe for podman desktop, in case we want to test an specific build')]
    $pdUrl="",
    [Parameter(HelpMessage='path for the exe for podman desktop to be tested')]
    $pdPath="",
    [Parameter(Mandatory,HelpMessage='folder on target host where assets are copied')]
    $targetFolder,
    [Parameter(Mandatory,HelpMessage='Results folder')]
    $resultsFolder="results",
    [Parameter(HelpMessage = 'Fork')]
    [string]$fork = "containers",
    [Parameter(HelpMessage = 'Branch')]
    [string]$branch = "main",
    [Parameter(HelpMessage = 'Npm Target to run')]
    [string]$npmTarget = "test:e2e:smoke",
    [Parameter(HelpMessage = 'Podman Installation path - bin directory')]
    [string]$podmanPath = "",
    [Parameter(HelpMessage = 'Initialize podman machine, default is 0/false')]
    $initialize='1',
    [Parameter(HelpMessage = 'Start Podman machine, default is 0/false')]
    $start='1',
    [Parameter(HelpMessage = 'Podman machine rootful flag, default 0/false')]
    $rootful='0'
)

function Download-PD {
    Write-Host "Downloading Podman Desktop from $pdUrl"
    curl.exe -L $pdUrl -o pd.exe
}

# Function to check if a command is available
function Command-Exists($command) {
    $null = Get-Command -Name $command -ErrorAction SilentlyContinue
    return $?
}

Write-Host "Podman desktop E2E runner script is being run..."

write-host "Switching to a target folder: " $targetFolder
cd $targetFolder
write-host "Create a resultsFolder in targetFolder: $resultsFolder"
mkdir -p $resultsFolder
$workingDir=Get-Location
write-host "Working location: " $workingDir

# Specify the user profile directory
$userProfile = $env:USERPROFILE

# Specify the shared tools directory
$toolsInstallDir = Join-Path $userProfile 'tools'

$podmanDesktopBinary=""

if (!$pdPath)
{
    if ($pdUrl) {
        # set binary path
        Download-PD
        $podmanDesktopBinary="$workingDir\pd.exe"
    }
} else {
    # set podman desktop binary path
    $podmanDesktopBinary=$pdPath
}

# Install or put the tool on the path, path is regenerated 
if (-not (Command-Exists "node -v")) {
    # Download and install the latest version of Node.js
    write-host "Installing node"
    # $nodejsLatestVersion = (Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' | Sort-Object -Property version -Descending)[0].version
    $nodejsLatestVersion = "v18.18.0"
    if (-not (Test-Path -Path "$toolsInstallDir\node-$nodejsLatestVersion-win-x64" -PathType Container)) {
        Invoke-WebRequest -Uri "https://nodejs.org/dist/$nodejsLatestVersion/node-$nodejsLatestVersion-win-x64.zip" -OutFile "$toolsInstallDir\nodejs.zip"
        Expand-Archive -Path "$toolsInstallDir\nodejs.zip" -DestinationPath $toolsInstallDir
    }
    $env:Path += ";$toolsInstallDir\node-$nodejsLatestVersion-win-x64"
}
# verify node, npm, yarn installation
node -v
npm -v
yarn --version

# GIT clone and checkout part
if (-not (Command-Exists "git version")) {
    # Download and install Git
    write-host "Installing git"
    $gitVersion = '2.42.0.2'
    if (-not (Test-Path -Path "$toolsInstallDir\git" -PathType Container)) {
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.42.0.windows.2/MinGit-$gitVersion-64-bit.zip" -OutFile "$toolsInstallDir\git.zip"
        Expand-Archive -Path "$toolsInstallDir\git.zip" -DestinationPath "$toolsInstallDir\git"
    }
    $env:Path += ";$toolsInstallDir\git\cmd"
}

if (-not (Command-Exists "podman")) {
    # Download and install the nightly podman for windows
    Write-host "Podman is not installed..."
    if ($podmanPath) {
        write-host "Settings podman binary location to PATH"
        $env:Path += ";$podmanPath"
    }
}

# Setup podman machine in the host system
if ($initialize -eq "1") {
    $flags=''
    if ($rootful -eq "1") {
        $flags="--rootful"
    }
    write-host "Initializing podman machine, command: podman machine init $flags"
    $logFile = "$workingDir\$resultsFolder\podman-machine-init.log"
    "podman machine init $flags" > $logFile
    if($flags) {
        # If more flag will be necessary, we have to consider composing the command other way
        # ie. https://stackoverflow.com/questions/6604089/dynamically-generate-command-line-command-then-invoke-using-powershell
        podman machine init $flags >> $logFile
    } else {
        podman machine init >> $logFile
    }
    if ($start -eq "1") {
        write-host "Starting podman machine..."
        "podman machine start" >> $logfile
        podman machine start >> $logFile
    }
    podman machine ls >> $logFile
}

# clean up previous folder
cd $workingDir
write-host "Working Dir: " $workingDir
if (Test-Path -Path "podman-desktop") {
    write-host "podman-desktop github repo exists"
} else {
    # Clone the GitHub repository and switch to the specified branch
    $repositoryURL ="https://github.com/$fork/podman-desktop.git"
    write-host "Checking out" $repositoryURL
    git clone $repositoryURL
    write-host "checking out into podman-desktop"
}

cd podman-desktop
write-host "checking out branch: $branch"
git checkout $branch

# Set PDOMAN_DESKTOP_BINARY if exists
if($podmanDesktopBinary) {
    $env:PODMAN_DESKTOP_BINARY="$podmanDesktopBinary";
}

# Setup CI env. var.
$env:CI = $true

## YARN INSTALL AND TEST PART
write-host "Installing dependencies"
yarn install
write-host "Running the e2e playwright tests using target: $npmTarget, binary used: $podmanDesktopBinary"
yarn $npmTarget

## Collect results
write-host "Collecting the results into: " "$workingDir\$resultsFolder\"

cp -r $workingDir\podman-desktop\tests\output\* $workingDir\$resultsFolder\

write-host "Script finished..."
