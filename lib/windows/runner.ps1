param(
    [Parameter(HelpMessage='url to download the exe for podman desktop, in case we want to test an specific build')]
    $pdUrl="",
    [Parameter(HelpMessage='path for the exe for podman desktop to be tested')]
    $pdPath="",
    [Parameter(Mandatory,HelpMessage='folder on target host where assets are copied')]
    $targetFolder,
    [Parameter(Mandatory,HelpMessage='Results folder')]
    $resultsFolder="results",
    [Parameter(HelpMessage = 'Podman Desktop Fork')]
    [string]$fork = "containers",
    [Parameter(HelpMessage = 'Podman Desktop Branch')]
    [string]$branch = "main",
    [Parameter(HelpMessage = 'Extension repo')]
    [string]$extRepo = "podman-desktop-redhat-account-ext",
    [Parameter(HelpMessage = 'Extension Fork')]
    [string]$extFork = "redhat-developer",
    [Parameter(HelpMessage = 'Extension Branch')]
    [string]$extBranch = "main",
    [Parameter(HelpMessage = 'Npm Target to run')]
    [string]$npmTarget = "test:e2e",
    [Parameter(HelpMessage = 'Run Extension Tests - 0/false')]
    $extTests='0',
    [Parameter(HelpMessage = 'Podman Installation path - bin directory')]
    [string]$podmanPath = "",
    [Parameter(HelpMessage = 'Initialize podman machine, default is 0/false')]
    $initialize='0',
    [Parameter(HelpMessage = 'Start Podman machine, default is 0/false')]
    $start='0',
    [Parameter(HelpMessage = 'Podman machine rootful flag, default 0/false')]
    $rootful='0',
    [Parameter(HelpMessage = 'Podman machine user-mode-networking flag, default 0/false')]
    $userNetworking='0',
    [Parameter(HelpMessage = 'Environmental variables to be passed from the CI into a script, tests parameterization')]
    $envVars='',
    [Parameter(HelpMessage = 'Path to a secret file')]
    [string]$secretFile=''
)

# Program Versions
$nodejsLatestVersion = "v20.11.1"
$gitVersion = '2.42.0.2'

$global:scriptEnvVars = @()

function Download-PD {
    Write-Host "Downloading Podman Desktop from $pdUrl"
    curl.exe -L $pdUrl -o pd.exe
}

# Function to check if a command is available
function Command-Exists($command) {
    $null = Get-Command -Name $command -ErrorAction SilentlyContinue
    return $?
}

function Copy-Exists($source, $target) {
    if (Test-Path -Path $source) {
        write-host "Copying all from $source"
        cp -r $source $target
    } else {
        write-host "$source does not exist"
    }
}

function Clone-Checkout($repo, $fork, $branch) {
    # clean up previous folder
    cd $workingDir
    write-host "Working Dir: " $workingDir
    write-host "Cloning " $repo
    if (Test-Path -Path $repo) {
        write-host "repository already exists"
    } else {
        # Clone the GitHub repository and switch to the specified branch
        $repositoryURL ="https://github.com/$fork/$repo.git"
        write-host "Checking out" $repositoryURL
        git clone $repositoryURL
        write-host "checking out into $repo"
    }
    # Checkout correct branch  
    cd $repo
    write-host "checking out branch: $branch"
    git checkout $branch
}

# Loading variables as env. var from the CI into image
function Load-Variables() {
    Write-Host "Loading Variables passed into image"
    Write-Host "Input String: '$envVars'"
    # Check if the input string is not null or empty
    if (-not [string]::IsNullOrWhiteSpace($envVars)) {
        # Split the input using comma separator
        $variables = $envVars -split ','

        foreach ($variable in $variables) {
            # Split each variable definition
            $parts = $variable -split '=', 2
            Write-Host "Processing $variable"

            # Check if the variable assignment is in VAR=Value format
            if ($parts.Count -eq 2) {
                $name = $parts[0].Trim()
                $value = $parts[1].Trim('"')

                # Set and test the environment variable
                Set-Item -Path "env:$name" -Value $value
                $global:scriptEnvVars += $name
            } else {
                Write-Host "Invalid variable assignment: $variable"
            }
        }
    } else {
        Write-Host "Input string is empty."
    }
}

# Loading a secrets into env. vars from the file
function Load-Secrets() {
    $secretFilePath="$resourcesPath/$secretFile"
    Write-Host "Loading Secrets from file: $secretFilePath"
    if (Test-Path $secretFilePath) {
        $properties = Get-Content $secretFilePath | ForEach-Object {
            # Ignore comments and empty lines
            if (-not $_.StartsWith("#") -and -not [string]::IsNullOrWhiteSpace($_)) {
                # Split each line into key-value pairs
                $key, $value = $_ -split '=', 2

                # Trim leading and trailing whitespaces
                $key = $key.Trim()
                $value = $value.Trim()

                # Set the environment variable
                Set-Item -Path "env:$key" -Value $value
                $global:scriptEnvVars += $key
            }
        }
        Write-Host "Secrets loaded from '$secretFilePath' and set as environment variables."
    } else {
        Write-Host "File '$secretFilePath' not found."
    }
}

# Execution beginning
Write-Host "Podman desktop E2E runner script is being run..."

write-host "Switching to a target folder: " $targetFolder
cd $targetFolder
write-host "Create a resultsFolder in targetFolder: $resultsFolder"
mkdir -p $resultsFolder
$workingDir=Get-Location
write-host "Working location: " $workingDir

# Capture resources path location
$resourcesPath=$workingDir

# Specify the user profile directory
$userProfile = $env:USERPROFILE

# Specify the shared tools directory
$toolsInstallDir = Join-Path $userProfile 'tools'

# load variables
Load-Variables

# load secrets
Load-Secrets

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
    if (-not (Test-Path -Path "$toolsInstallDir\node-$nodejsLatestVersion-win-x64" -PathType Container)) {
        Invoke-WebRequest -Uri "https://nodejs.org/dist/$nodejsLatestVersion/node-$nodejsLatestVersion-win-x64.zip" -OutFile "$toolsInstallDir\nodejs.zip"
        Expand-Archive -Path "$toolsInstallDir\nodejs.zip" -DestinationPath $toolsInstallDir
    }
    $env:Path += ";$toolsInstallDir\node-$nodejsLatestVersion-win-x64"
}
# verify node, npm, yarn installation
node -v
npm -v

# Install Yarn
write-host "Installing yarn"
npm install -g yarn
yarn --version

# GIT clone and checkout part
if (-not (Command-Exists "git version")) {
    # Download and install Git
    write-host "Installing git"
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
        write-host "Content of the $podmanPath"
        $items = Get-ChildItem -Path $myPath
        foreach ($item in $items) {
            Write-Host $item.FullName
        }
        write-host "Settings podman binary location to PATH"
        $env:Path += ";$podmanPath"
    }
}

# Test podman version installed
podman -v

# Setup podman machine in the host system
if ($initialize -eq "1") {
    $flags = ""
    if ($rootful -eq "1") {
        $flags += "--rootful "
    }
    if ($userNetworking -eq "1") {
        $flags += "--user-mode-networking "
    }
    $flags = $flags.Trim()
    $flagsArray = $flags -split ' '
    write-host "Initializing podman machine, command: podman machine init $flags"
    $logFile = "$workingDir\$resultsFolder\podman-machine-init.log"
    "podman machine init $flags" > $logFile
    if($flags) {
        # If more flag will be necessary, we have to consider composing the command other way
        # ie. https://stackoverflow.com/questions/6604089/dynamically-generate-command-line-command-then-invoke-using-powershell
        podman machine init $flagsArray >> $logFile
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


# checkout podman-desktop
Clone-Checkout 'podman-desktop' $fork $branch

if ($extTests -eq "1") {
    Clone-Checkout $extRepo $extFork $extBranch
}

# Set PDOMAN_DESKTOP_BINARY if exists
if($podmanDesktopBinary) {
    $env:PODMAN_DESKTOP_BINARY="$podmanDesktopBinary";
}

# Setup CI env. var.
$env:CI = $true

if ($extTests -eq "1") {
    $env:PODMAN_DESKTOP_ARGS="$workingDir\podman-desktop"
}

## YARN INSTALL AND TEST PART PODMAN-DESKTOP
cd "$workingDir\podman-desktop"
write-host "Installing dependencies of podman-desktop"
yarn install 2>&1 | Tee-Object -FilePath 'output.log' -Append
if ($extTests -ne "1") {
    write-host "Running the e2e playwright tests using target: $npmTarget, binary used: $podmanDesktopBinary"
    yarn $npmTarget 2>&1 | Tee-Object -FilePath 'output.log' -Append
} else {
    write-host "Building podman-desktop to run e2e from extension repo"
    yarn test:e2e:build 2>&1 | Tee-Object -FilePath 'output.log' -Append
}

## Collect results
mkdir -p "$workingDir\$resultsFolder\podman-desktop"
$target="$workingDir\$resultsFolder\podman-desktop"
write-host "Collecting the results into: " $target
Copy-Exists $workingDir\podman-desktop\output.log $target
Copy-Exists $workingDir\podman-desktop\tests\output\* $target
Copy-Exists $workingDir\podman-desktop\tests\playwright\output\* $target
# reduce the size of the artifacts
if (Test-Path "$target\traces\raw") {
    rm -f "$target\traces\raw"
}

## run extension e2e tests
if ($extTests -eq "1") {
    cd "$workingDir\$extRepo"
    write-host "Installing dependencies of $repo"
    yarn install 2>&1 | Tee-Object -FilePath 'output.log' -Append
    write-host "Running the e2e playwright tests using target: $npmTarget"
    yarn $npmTarget 2>&1 | Tee-Object -FilePath 'output.log' -Append
    ## Collect results
    mkdir -p "$workingDir\$resultsFolder\$extRepo"
    $target="$workingDir\$resultsFolder\$extRepo"
    write-host "Collecting the results into: " $target
    Copy-Exists $workingDir\podman-desktop\output.log $target
    Copy-Exists $workingDir\podman-desktop\tests\output\* $target
    Copy-Exists $workingDir\podman-desktop\tests\playwright\output\* $target
    # reduce the size of the artifacts
    if (Test-Path "$target\traces\raw") {
        rm -f "$target\traces\raw"
    }
}

# Cleaning up (secrets, env. vars.)
write-host "Purge env vars: $scriptEnvVars"
foreach ($var in $scriptEnvVars) {
    Remove-Item -Path "env:\$var"
}
Write-Host "Remove secrets file $resourcesPath/$secretFile from the target"
Remove-Item -Path "$resourcesPath/$secretFile"

write-host "Script finished..."
