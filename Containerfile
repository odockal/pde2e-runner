ARG OS

FROM quay.io/rhqp/deliverest:v0.0.7 AS base
LABEL org.opencontainers.image.authors="Ondrej Dockal<odockal@redhat.com> Anton Misskii<amisskii@redhat.com"
ENV ASSETS_FOLDER=/opt/pde2e-runner

FROM base AS darwin
COPY /lib/darwin/ ${ASSETS_FOLDER}/
COPY /lib/unix/scripts/ ${ASSETS_FOLDER}/scripts/
ENV OS=darwin

FROM base AS windows
COPY /lib/windows/ ${ASSETS_FOLDER}/
ENV OS=windows

FROM base AS linux
ENV OS=linux

FROM linux AS rhel
COPY /lib/rhel/ ${ASSETS_FOLDER}/
COPY /lib/unix/scripts/ ${ASSETS_FOLDER}/scripts/

FROM ${OS}
