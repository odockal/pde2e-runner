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
    [string]$branch = "main"
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
mkdir $resultsFolder
$workingDir=Get-Location
write-host "Working location: " $workingDir

$podman_desktop_binary=""

if (!$pdPath)
{
    if ($pdUrl) {
        # set binary path
        Download-PD
        $podman_desktop_binary="$workingDir\pd.exe"
    }
} else {
    # set podman desktop binary path
    $podman_desktop_binary=$pdPath
}

# verify node, npm, yarn installation
node -v
npm -v
yarn --version

# GIT clone and checkout part
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
    cd podman-desktop
    write-host "checking out branch: $branch"
    git checkout $branch
}

# Set PDOMAN_DESKTOP_BINARY if exists
if($podman_desktop_binary) {
    $env:PODMAN_DESKTOP_BINARY="$podman_desktop_binary";
}

## YARN INSTALL AND TEST PART
write-host "Installing dependencies"
yarn install
write-host "Running the e2e playwright tests using, can use Binary: $env:PODMAN_DESKTOP_BINARY"
yarn test:e2e:smoke

## Collect results
write-host "Collecting the results into: " "$workingDir\$resultsFolder\"

cp -r $workingDir\podman-desktop\tests\output\* $workingDir\$resultsFolder\

start-sleep -Seconds 10
write-host "Script finished..."
