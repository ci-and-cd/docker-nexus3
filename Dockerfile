# see: https://github.com/sonatype/docker-nexus3/blob/master/Dockerfile

FROM centos:centos7


ARG NEXUS_VERSION=3.16.2-01
ARG NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz
ARG NEXUS_DOWNLOAD_SHA256_HASH=d6e8016d389b35f2dc569c981a8076f0d5fcca54778c611c601db2aa9a984cf0


# configure nexus runtime
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus \
    NEXUS_DATA=/nexus-data \
    NEXUS_CONTEXT='' \
    SONATYPE_WORK=${SONATYPE_DIR}/sonatype-work \
    DOCKER_TYPE='docker'


ARG NEXUS_REPOSITORY_MANAGER_COOKBOOK_VERSION="release-0.5.20190212-155606.d1afdfe"
ARG NEXUS_REPOSITORY_MANAGER_COOKBOOK_URL="https://github.com/sonatype/chef-nexus-repository-manager/releases/download/${NEXUS_REPOSITORY_MANAGER_COOKBOOK_VERSION}/chef-nexus-repository-manager.tar.gz"

ADD solo.json.erb /var/chef/solo.json.erb

# Install using chef-solo
# Chef version locked to avoid needing to accept the EULA on behalf of whomever builds the image
RUN curl -L https://www.getchef.com/chef/install.sh | bash -s -- -v 14.12.9 \
    && /opt/chef/embedded/bin/erb /var/chef/solo.json.erb > /var/chef/solo.json \
    && chef-solo \
       --recipe-url ${NEXUS_REPOSITORY_MANAGER_COOKBOOK_URL} \
       --json-attributes /var/chef/solo.json \
    && rpm -qa *chef* | xargs rpm -e \
    && rpm --rebuilddb \
    && rm -rf /etc/chef \
    && rm -rf /opt/chefdk \
    && rm -rf /var/cache/yum \
    && rm -rf /var/chef \
    && set -ex \
    && OLD_UID=$(id -u nexus) \
    && OLD_GID=$(id -u nexus) \
    && usermod -u 1000  nexus \
    && groupmod -g 1000 nexus \
    && chown -hR nexus:nexus ${NEXUS_HOME} ${NEXUS_DATA} ${SONATYPE_WORK} \
    && find -user ${OLD_UID} -path "/" -prune -exec chown nexus:nexus {} ";"



#RUN set -ex \
#  && mkdir -p /opt/sonatype/nexus \
#  && useradd -c "Nexus Repository Manager user" --home-dir /opt/sonatype/nexus -s /bin/false -u 1000 -U nexus \
#  && chown nexus /opt/sonatype/nexus \
#  && chgrp nexus /opt/sonatype/nexus
#
#COPY --chown=root:root   --from=sonatype/nexus3:3.16.2 /usr/lib/jvm /usr/lib/jvm
#COPY --chown=root:root   --from=sonatype/nexus3:3.16.2 /opt/ opt/
#COPY --chown=nexus:nexus --from=sonatype/nexus3:3.16.2 /nexus-data /nexus-data
COPY --chown=root:root   --from=cirepo/waitforit:2.2.0-archive /data/root /
COPY --chown=root:root   docker /

ENV ARIA2C_DOWNLOAD aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0
RUN set -ex \
  && chmod 755 /*.sh \
  && yum -y install epel-release \
  && yum -y install socat \
  && yum -y install aria2 httpie unzip \
  && yum -y install sudo \
  && echo "nexus ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/nexus \
  && chmod 0440 /etc/sudoers.d/nexus \
  && yum -y clean all \
  && cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

## java.io.FileNotFoundException: /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.212.b04-0.el7_6.x86_64/jre/lib/tzdb.dat (No such file or directory)
## java.lang.NoClassDefFoundError: Could not initialize class sun.util.calendar.ZoneInfoFile
## [Timezone Updater Tool](http://www.oracle.com/us/technologies/java/tzupdater-readme-136440.html)
## [Java SE TZUpdater Downloads](https://www.oracle.com/technetwork/java/javase/downloads/tzupdater-download-513681.html)
#RUN alternatives --install /usr/bin/java java /usr/java/default/bin/java 500 \
#  && TZUPDATER_DIR="tzupdater-2.2.0" \
#  && TZUPDATER_ZIP="tzupdater-2_2_0.zip" \
#  && sudo mkdir -p /data \
#  && sudo chmod 777 /data \
#  && cd /data \
#  && if [ ! -f /data/${TZUPDATER_ZIP} ]; then \
#       ${ARIA2C_DOWNLOAD} --header="Cookie: oraclelicense=accept-securebackup-cookie" \
#       -d /data -o ${TZUPDATER_ZIP} ${IMAGE_ARG_FILESERVER:-http://download.oracle.com}/otn-pub/java/tzupdater/2.2.0/tzupdater-2_2_0.zip; \
#     fi \
#  && unzip /data/${TZUPDATER_ZIP} \
#  && sudo cp -f /data/${TZUPDATER_DIR}/tzupdater.jar /tzupdater.jar \
#  && rm -rf /data/${TZUPDATER_DIR} \
#  && rm -f /data/${TZUPDATER_ZIP} \

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
