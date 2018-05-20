
FROM sonatype/nexus3:3.11.0

ARG build_fileserver

USER root

RUN yum install epel-release -y \
    && yum -y install socat \
    && yum install aria2 httpie -y \
    && yum clean all -y \
    && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ADD docker/install_waitforit.sh /root/
RUN /root/install_waitforit.sh

COPY docker/nexus3_utils.sh /nexus3_utils.sh
COPY docker/init_nexus3.sh /init_nexus3.sh
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /*.sh

USER nexus
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/sonatype/start-nexus-repository-manager.sh"]
