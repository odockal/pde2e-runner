# Prepare remote machine powershell script
$podmanMachine="podman-machine"
$remoteMachine="remote-machine"
write-host "Preparing podman machine $podmanMachine"

podman machine init --now $podmanMachine

write-host "Podman Machine should be up and running:"
podman machine ls --format json

# variables
$tinyImage="quay.io/podman/hello:latest" # ~0'8MB
$smallImage="quay.io/sclorg/nginx-122-micro-c9s:20230718" # ~70MB
$mediumImage="docker.io/library/nginx:latest" # ~200MB
$largeImage="registry.access.redhat.com/ubi8/httpd-24-3:latest" # ~460MB

$testImage=$tinyImage

# pull the image
podman pull $testImage

# repeat 10 times
for ($imgNum = 1; $imgNum -lt 11; $imgNum++) {
    # tag (in pd, effectively, copy)
    podman tag $testImage "quay.io/my-image-$imgNum:latest"
    # create container
    podman run -d --name "my-container-$imgNum" $testImage
    #create pod
    podman pod create --name "my-pod-$imgNum"
}

# Prepare the remote-machine for remote connection

# Get default system connection, load it from json
$json = podman system connection ls --format json | ConvertFrom-Json
foreach ($item in $json) { 
    if ($item.Default -match "True" ) { 
        $name=$($item.Name) 
        $uri=$($item.URI)
        $identity=$($item.Identity)
    }
}

write-host "Default connection - Name: $name, URI: $uri, Identity: $identity"

# Clean up the access to the podman machine
# Do not remove ~/.local/share/containers/podman as there are keys to the machine
podman system connection rm $podmanMachine
podman system connection rm $podmanMachine-root

# remove default connections and other podman related files fron APPDATA\containers
rm -r $env:APPDATA\containers\*

# remove other configuration files from USERPROFILE\.config\containers
rm -r $env:USERPROFILE\.config\containers

# create a connection from previous information
podman system connection add $remoteMachine --identity $identity $uri

# check connection
podman system connection ls --format json

# run the remote e2e tests...