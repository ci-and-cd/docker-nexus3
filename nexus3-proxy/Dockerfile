
# see: https://github.com/nginxinc/docker-nginx/blob/3e8a6ee0603bf6c9cd8846c5fa43e96b13b0f44b/mainline/alpine/Dockerfile

FROM nginx:1.10.2-alpine

COPY docker/render.sh /render.sh
COPY docker/nexus_docker.conf_tpl /nexus_docker.conf_tpl
COPY docker/entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
