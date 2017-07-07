#!/usr/bin/env sh

### environments
NEXUS_DEPLOYMENT_USER="deployment"
if [ -z "${DOCKER_MIRROR_DOMAIN}" ]; then echo "DOCKER_MIRROR_DOMAIN not set"; exit 1; fi
if [ -z "${DOCKER_MIRROR_PORT}" ]; then echo "DOCKER_MIRROR_PORT not set"; exit 1; fi
if [ -z "${DOCKER_REGISTRY_DOMAIN}" ]; then echo "DOCKER_REGISTRY_DOMAIN not set"; exit 1; fi
if [ -z "${DOCKER_REGISTRY_PORT}" ]; then echo "DOCKER_REGISTRY_PORT not set"; exit 1; fi
if [ -z "${FILESERVER_DOMAIN}" ]; then echo "FILESERVER_DOMAIN not set"; exit 1; fi
if [ -z "${NEXUS3_DEPLOYMENT_PASSWORD}" ]; then echo "NEXUS3_DEPLOYMENT_PASSWORD not set"; exit 1; fi
if [ -z "${NEXUS3_DOMAIN}" ]; then echo "NEXUS3_DOMAIN not set"; exit 1; fi
if [ -z "${NEXUS3_PORT}" ]; then echo "NEXUS3_PORT not set"; exit 1; fi
if [ -z "${NEXUS3_PROXY_HOSTNAME}" ]; then echo "NEXUS3_PROXY_HOSTNAME not set"; exit 1; fi

### vars
NEXUS_DEPLOYMENT_AUTH_HEADER="'Basic $(echo -ne "${NEXUS_DEPLOYMENT_USER}:${NEXUS3_DEPLOYMENT_PASSWORD}" | base64)'"

if [ ! -z "${NEXUS3_CONTEXT}" ]; then
    SED_FILESERVER_PATH="s#FILESERVER_PATH#${NEXUS3_CONTEXT}/repository/files#"
else
    SED_FILESERVER_PATH="s#FILESERVER_PATH#repository/files#"
fi

target_directory="$1"
sed "s/DOCKER_MIRROR_DOMAIN/${DOCKER_MIRROR_DOMAIN}/; s/DOCKER_MIRROR_URL/${DOCKER_MIRROR_DOMAIN}:${DOCKER_MIRROR_PORT}/;" nexus_docker.conf_tpl | \
    sed "s/DOCKER_REGISTRY_DOMAIN/${DOCKER_REGISTRY_DOMAIN}/; s/DOCKER_REGISTRY_URL/${DOCKER_REGISTRY_DOMAIN}:${DOCKER_REGISTRY_PORT}/;" | \
    sed "s/NEXUS3_PROXY_HOSTNAME/${NEXUS3_PROXY_HOSTNAME}/; s/NEXUS_URL/${NEXUS3_DOMAIN}:${NEXUS3_PORT}/;" | \
    sed "${SED_FILESERVER_PATH}; s#FILESERVER_DOMAIN#${FILESERVER_DOMAIN}#; s###" | \
    sed "s#_NEXUS_DEPLOYMENT_AUTH#${NEXUS_DEPLOYMENT_AUTH_HEADER}#" > ${target_directory}/nexus_docker.conf
