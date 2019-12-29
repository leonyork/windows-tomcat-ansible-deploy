ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}

ARG PYWINRM_VERSION
ARG ANSIBLE_VERSION
RUN apk add --no-cache \
    py-pip musl-dev python2-dev libffi-dev openssl-dev jq gcc \
    && pip install "pywinrm==${PYWINRM_VERSION}" "ansible==${ANSIBLE_VERSION}"