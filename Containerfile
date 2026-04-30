ARG OS

FROM quay.io/rhqp/deliverest:v0.0.7 AS base
LABEL org.opencontainers.image.authors="Ondrej Dockal<odockal@redhat.com>"
ENV ASSETS_FOLDER=/opt/pde2e-runner

FROM base AS os-darwin
COPY /lib/unix/ ${ASSETS_FOLDER}/

FROM base AS os-rhel
COPY /lib/unix/ ${ASSETS_FOLDER}/
COPY /lib/rhel/ ${ASSETS_FOLDER}/

FROM base AS os-windows
COPY /lib/windows/ ${ASSETS_FOLDER}/

FROM os-${OS}
ARG ENTRYPOINT_OS
ENV OS=${ENTRYPOINT_OS}
