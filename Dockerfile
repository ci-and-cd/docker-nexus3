
FROM sonatype/nexus3:3.2.1

ARG build_fileserver

USER root

#RUN http_proxy=${host}:${port} https_proxy=${host}:${port} \
RUN curl -L -o /bin/waitforit ${build_fileserver}/maxcnunes/waitforit/releases/download/v1.4.0/waitforit-linux_amd64 && \
    chmod 755 /bin/waitforit && \
    cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

COPY docker/nexus3_utils.sh /opt/sonatype/nexus/nexus3_utils.sh
COPY docker/init_nexus3.sh /opt/sonatype/nexus/init_nexus3.sh
COPY docker/entrypoint.sh /opt/sonatype/nexus/entrypoint.sh
RUN chmod 755 /opt/sonatype/nexus/*.sh

USER nexus
ENTRYPOINT ["/opt/sonatype/nexus/entrypoint.sh"]
CMD ["bin/nexus", "run"]
