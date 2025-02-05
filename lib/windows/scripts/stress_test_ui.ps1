# Powershell script for podman setup
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
    podman run -d --name "my-container-$imgNum" "quay.io/my-image-$imgNum:latest"
    #create pod
    podman pod create --name "my-pod-$imgNum"
}

# run the stress tests...