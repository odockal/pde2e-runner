# pde2e-runner
Podman Desktop E2E playwright test execution image

## Usage examples of pde2e-runner image

```sh
podman run --rm -d --name pde2e-runner-run \
          -e TARGET_HOST=$(cat host) \
          -e TARGET_HOST_USERNAME=$(cat username) \
          -e TARGET_HOST_KEY_PATH=/data/id_rsa \
          -e TARGET_FOLDER=pd-e2e-runner \
          -e TARGET_RESULTS=results \
          -e OUTPUT_FOLDER=/data \
          -e DEBUG=true \
          -v $PWD:/data:z \
          quay.io/odockal/pde2e-runner:v0.0.1-snapshot  \
            pd-e2e-runner/run.ps1 \
            -targetFolder pd-e2e-runner \
            -resultsFolder results \
            -fork containers \
            -branch main
            -npmTarget "test:e2e:smoke"
```

## Get the image logs
```sh
podman logs -f pde2e-podman-run
```