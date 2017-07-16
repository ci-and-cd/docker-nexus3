#!/bin/sh

if [ -z "${build_fileserver}" ]; then build_fileserver="https://github.com"; fi
#http_proxy=${host}:${port} https_proxy=${host}:${port} \
#curl -L -o /bin/waitforit ${build_fileserver}/maxcnunes/waitforit/releases/download/v1.4.0/waitforit-linux_amd64 && \
aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0 -d /bin -o waitforit ${build_fileserver}/maxcnunes/waitforit/releases/download/v1.4.0/waitforit-linux_amd64 && \
    chmod 755 /bin/waitforit
