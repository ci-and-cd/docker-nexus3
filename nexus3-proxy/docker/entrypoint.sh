#!/usr/bin/env sh

set -e

if [ "$1" == 'nginx' ]; then
    /render.sh "/etc/nginx/conf.d"
    exec "$@"
else
    exec "$@"
fi
