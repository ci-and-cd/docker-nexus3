
FROM sonatype/nexus3:3.4.0

ARG build_fileserver

USER root

RUN yum install epel-release -y && \
    yum -y install socat && \
    yum install aria2 -y && \
    yum clean all -y

ADD docker/install_waitforit.sh /root/
RUN /root/install_waitforit.sh

RUN cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

COPY docker/nexus3_utils.sh /opt/sonatype/nexus/nexus3_utils.sh
COPY docker/init_nexus3.sh /opt/sonatype/nexus/init_nexus3.sh
COPY docker/entrypoint.sh /opt/sonatype/nexus/entrypoint.sh
RUN chmod 755 /opt/sonatype/nexus/*.sh

USER nexus
ENTRYPOINT ["/opt/sonatype/nexus/entrypoint.sh"]
CMD ["bin/nexus", "run"]
