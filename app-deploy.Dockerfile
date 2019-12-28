ARG ALPINE_VERSION
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
    py-pip musl-dev python2-dev libffi-dev openssl-dev jq gcc \
    && pip install "pywinrm==0.4.1" "ansible==2.9.2"