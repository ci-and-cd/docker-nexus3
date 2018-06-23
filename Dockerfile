# see: https://github.com/sonatype/docker-nexus3/blob/master/Dockerfile

FROM sonatype/nexus3:3.12.1

ARG build_fileserver
ENV ARIA2C_DOWNLOAD aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0

USER root

RUN yum install epel-release -y \
    && yum -y install socat \
    && yum install aria2 httpie -y \
    && yum clean all -y \
    && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo ===== Install waitforit ===== \
    && ${ARIA2C_DOWNLOAD} -d /usr/bin -o "waitforit" "http://o9wbz99tz.bkt.clouddn.com/maxcnunes/waitforit/releases/download/v2.2.0/waitforit-linux_amd64" \
    && chmod 755 /usr/bin/waitforit

# Short term workaround of issue "Insufficient configured threads"
#see: https://issues.sonatype.org/browse/NEXUS-16565
RUN cat ${NEXUS_HOME}/etc/jetty/jetty.xml \
    && grep threadpool ${NEXUS_HOME}/etc/jetty/jetty.xml \
    && sed -i 's|<New id="threadpool" class="org.sonatype.nexus.bootstrap.jetty.InstrumentedQueuedThreadPool"/>|<New id="threadpool" class="org.sonatype.nexus.bootstrap.jetty.InstrumentedQueuedThreadPool"><Set name="maxThreads">400</Set></New>|' ${NEXUS_HOME}/etc/jetty/jetty.xml \
    && grep threadpool ${NEXUS_HOME}/etc/jetty/jetty.xml

COPY docker/nexus3_utils.sh /nexus3_utils.sh
COPY docker/init_nexus3.sh /init_nexus3.sh
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod 755 /*.sh

USER nexus
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/opt/sonatype/start-nexus-repository-manager.sh"]
