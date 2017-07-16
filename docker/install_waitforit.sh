#!/bin/sh

if [ -z "${build_fileserver}" ]; then build_fileserver="https://github.com"; fi
#http_proxy=${host}:${port} https_proxy=${host}:${port} \
curl -L -o /bin/waitforit ${build_fileserver}/maxcnunes/waitforit/releases/download/v1.4.0/waitforit-linux_amd64 && \
    chmod 755 /bin/waitforit
