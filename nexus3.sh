#!/usr/bin/env bash

# /etc/systemd/system/docker.service.d/http-proxy.conf
mkdir -p /etc/systemd/system/docker.service.d
touch /etc/systemd/system/docker.service.d/http-proxy.conf
#[Service]
#Environment="HTTP_PROXY=http://${host}:${port}"

# /etc/profile
#export http_proxy=${host}:${port}
#export https_proxy=${host}:${port}

export INFRASTRUCTURE=internal
export DOCKER_MIRROR_DOMAIN=mirror.docker.${INFRASTRUCTURE}
export DOCKER_REGISTRY_DOMAIN=registry.docker.${INFRASTRUCTURE}
export FILESERVER_DOMAIN=fileserver.${INFRASTRUCTURE}
export INTERNAL_NEXUS=none
export NEXUS_DOMAIN=nexus3.${INFRASTRUCTURE}
export NEXUS_HOSTNAME=nexus3.${INFRASTRUCTURE}
export NEXUS_PROXY_HOSTNAME=nexus.${INFRASTRUCTURE}

#(cd nexus3 && docker-compose build)
(cd nexus3 && docker-compose up -d)
#(cd nexus3-proxy && docker-compose build)
(cd nexus3-proxy && docker-compose up -d)
#docker network create oss-network
