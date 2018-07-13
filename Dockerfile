# see: https://github.com/sonatype/docker-nexus3/blob/master/Dockerfile

FROM centos:centos7


ENV JAVA_HOME=/opt/java

# configure nexus runtime
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
    NEXUS_DATA=/nexus-data \
    NEXUS_CONTEXT='' \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work \
    DOCKER_TYPE='docker'


RUN set -ex \
  && mkdir -p /opt/sonatype/nexus \
  && useradd -c "Nexus Repository Manager user" --home-dir /opt/sonatype/nexus -s /bin/false -u 1000 -U nexus \
  && chown nexus /opt/sonatype/nexus \
  && chgrp nexus /opt/sonatype/nexus


COPY --chown=root:root   --from=sonatype/nexus3:3.12.1 /opt/ opt/
COPY --chown=nexus:nexus --from=sonatype/nexus3:3.12.1 /nexus-data /nexus-data
COPY --chown=root:root   --from=cirepo/waitforit:2.2.0-archive /data/root /
COPY --chown=root:root   docker /


RUN set -ex \
  && chmod 755 /*.sh \
  && yum -y install epel-release \
  && yum -y install socat \
  && yum -y install aria2 httpie \
  && yum -y clean all \
  && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# Short term workaround of issue "Insufficient configured threads"
#see: https://issues.sonatype.org/browse/NEXUS-16565
RUN set -ex \
  && cat ${NEXUS_HOME}/etc/jetty/jetty.xml \
  && grep threadpool ${NEXUS_HOME}/etc/jetty/jetty.xml \
  && sed -i 's|<New id="threadpool" class="org.sonatype.nexus.bootstrap.jetty.InstrumentedQueuedThreadPool"/>|<New id="threadpool" class="org.sonatype.nexus.bootstrap.jetty.InstrumentedQueuedThreadPool"><Set name="maxThreads">400</Set></New>|' ${NEXUS_HOME}/etc/jetty/jetty.xml \
  && grep threadpool ${NEXUS_HOME}/etc/jetty/jetty.xml


VOLUME ${NEXUS_DATA}

EXPOSE 8081
USER nexus
ENV INSTALL4J_ADD_VM_PARAMS="-Xms1200m -Xmx1200m -XX:MaxDirectMemorySize=2g -Djava.util.prefs.userRoot=${NEXUS_DATA}/javaprefs"

ENTRYPOINT ["/entrypoint.sh"]
CMD ["${SONATYPE_DIR}/start-nexus-repository-manager.sh"]
