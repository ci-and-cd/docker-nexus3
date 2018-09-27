#!/usr/bin/env bash

init_nexus() {
    . nexus3_utils.sh

    if type -p waitforit > /dev/null; then
        #  -debug
        waitforit -address=tcp://$(nexus_address) -timeout=180
        local nexus_running="$?"
        echo "nexus_running: ${nexus_running}"
        if [ ${nexus_running} -gt 0 ]; then
            echo "nexus is not running"
            exit 1
        fi
    fi

    # default username/password admin/admin123
    nexus_login "admin" "admin123"

    # setup account deployment's password
    # see: http://stackoverflow.com/questions/40966763/how-do-i-create-a-user-with-the-a-role-with-the-minimal-set-of-privileges-deploy
    # see: https://books.sonatype.com/nexus-book/reference3/security.html#privileges
    if [ -z "${NEXUS3_DEPLOYMENT_PASSWORD}" ]; then
        NEXUS3_DEPLOYMENT_PASSWORD="deployment"
    fi
    nexus_user "deployment" "${NEXUS3_DEPLOYMENT_PASSWORD}"

    local maven_group_members="maven-releases,maven-snapshots,maven-central"

    nexus_maven2_hosted "maven-thirdparty"
    maven_group_members="${maven_group_members},maven-thirdparty"

    # sonatype
    nexus_maven2_proxy "sonatype-releases" "RELEASE" "https://oss.sonatype.org/content/repositories/releases/"
    maven_group_members="${maven_group_members},sonatype-releases"
    nexus_maven2_proxy "sonatype-snapshots" "SNAPSHOT" "https://oss.sonatype.org/content/repositories/snapshots/"
    maven_group_members="${maven_group_members},sonatype-snapshots"

    # proxy private nexus
    # nexus2 /nexus/content/groups/public/
    if [[ "${INFRASTRUCTURE_INTERNAL_NEXUS2}" == http* ]]; then
        nexus_maven2_proxy "private-nexus2.snapshot" "SNAPSHOT" "${INFRASTRUCTURE_INTERNAL_NEXUS2}/nexus/content/groups/public/"
        maven_group_members="${maven_group_members},private-nexus2.snapshot"
        nexus_maven2_proxy "private-nexus2.release" "RELEASE" "${INFRASTRUCTURE_INTERNAL_NEXUS2}/nexus/content/groups/public/"
        maven_group_members="${maven_group_members},private-nexus2.release"
    fi
    # nexus3 /nexus/repository/maven-public/
    if [[ "${INFRASTRUCTURE_INTERNAL_NEXUS3}" == http* ]]; then
        nexus_maven2_proxy "private-nexus3.snapshot" "SNAPSHOT" "${INFRASTRUCTURE_INTERNAL_NEXUS3}/nexus/repository/maven-public/"
        maven_group_members="${maven_group_members},private-nexus3.snapshot"
        nexus_maven2_proxy "private-nexus3.release" "RELEASE" "${INFRASTRUCTURE_INTERNAL_NEXUS3}/nexus/repository/maven-public/"
        maven_group_members="${maven_group_members},private-nexus3.release"
    fi

    # https://github.com/spring-projects/spring-framework/wiki/Spring-repository-FAQ
    nexus_maven2_proxy "spring-libs-release" "RELEASE" "http://repo.spring.io/libs-release"
    nexus_maven2_proxy "spring-libs-milestone" "RELEASE" "http://repo.spring.io/libs-milestone"
    nexus_maven2_proxy "spring-libs-snapshot" "SNAPSHOT" "http://repo.spring.io/libs-snapshot"
    maven_group_members="${maven_group_members},spring-libs-release,spring-libs-milestone,spring-libs-snapshot"
    nexus_maven2_proxy "spring-release" "RELEASE" "http://repo.spring.io/release"
    nexus_maven2_proxy "spring-milestone" "RELEASE" "http://repo.spring.io/milestone"
    nexus_maven2_proxy "spring-snapshot" "SNAPSHOT" "http://repo.spring.io/snapshot"
    maven_group_members="${maven_group_members},spring-release,spring-milestone,spring-snapshot"
    nexus_maven2_proxy "spring-libs-release-local" "RELEASE" "http://repo.spring.io/libs-release-local"
    nexus_maven2_proxy "spring-libs-milestone-local" "RELEASE" "http://repo.spring.io/libs-milestone-local"
    nexus_maven2_proxy "spring-libs-snapshot-local" "SNAPSHOT" "http://repo.spring.io/libs-snapshot-local"
    maven_group_members="${maven_group_members},spring-libs-release-local,spring-libs-milestone-local,spring-libs-snapshot-local"
    nexus_maven2_proxy "groovy-bintray" "RELEASE" "https://dl.bintray.com/groovy/maven"
    maven_group_members="${maven_group_members},groovy-bintray"

    # http://conjars.org
    nexus_maven2_proxy "conjars.org" "RELEASE" "http://conjars.org/repo/"
    maven_group_members="${maven_group_members},conjars.org"
    # https://clojars.org
    nexus_maven2_proxy "clojars.org" "RELEASE" "https://clojars.org/repo/"
    maven_group_members="${maven_group_members},clojars.org"
    # http://www.codehaus.org/mechanics/maven/
    nexus_maven2_proxy "codehaus-mule-repo" "RELEASE" "https://repository-master.mulesoft.org/nexus/content/groups/public/"
    maven_group_members="${maven_group_members},codehaus-mule-repo"
    # http://repo.jenkins-ci.org
    nexus_maven2_proxy "repo.jenkins-ci.org" "RELEASE" "http://repo.jenkins-ci.org/public/"
    maven_group_members="${maven_group_members},repo.jenkins-ci.org"
    # https://developer.jboss.org/wiki/MavenRepository
    nexus_maven2_proxy "org.jboss.repository" "RELEASE" "https://repository.jboss.org/nexus/content/repositories/public/"
    maven_group_members="${maven_group_members},org.jboss.repository"

    # apache snapshots
    nexus_maven2_proxy "apache-snapshots" "SNAPSHOT" "https://repository.apache.org/content/repositories/snapshots/"
    maven_group_members="${maven_group_members},apache-snapshots"

    # Forked github-maven-plugins that upload faster
    nexus_maven2_proxy "github-mvn-repo-github-maven-plugins" "RELEASE" "https://raw.github.com/ci-and-cd/maven-plugins/mvn-repo/"
    maven_group_members="${maven_group_members},github-mvn-repo-github-maven-plugins"
    # decrypt maven repository password for gradle build
    nexus_maven2_proxy "github-mvn-repo-maven-settings-decoder" "RELEASE" "https://raw.github.com/ci-and-cd/maven-settings-decoder/mvn-repo/"
    maven_group_members="${maven_group_members},github-mvn-repo-maven-settings-decoder"
    # Fixed issue of merge snapshotVersion
    nexus_maven2_proxy "github-mvn-repo-wagon-maven-plugin" "RELEASE" "https://raw.github.com/ci-and-cd/wagon-maven-plugin/mvn-repo/"
    maven_group_members="${maven_group_members},github-mvn-repo-wagon-maven-plugin"

    nexus_maven_group "maven-public" "${maven_group_members}"

    # Raw Repositories, Maven Sites and More see: https://books.sonatype.com/nexus-book/3.0/reference/raw.html
    #nexus_raw_proxy "node-dist" "https://nodejs.org/dist/"
    # https://npm.taobao.org/dist is same as https://npm.taobao.org/mirrors/node/
    nexus_raw_proxy "node-dist-taobao" "https://npm.taobao.org/dist/"
    nexus_raw_proxy "node-dist-official" "https://nodejs.org/dist/"
    nexus_raw_group "node-dist" "node-dist-taobao,node-dist-official"
    nexus_raw_proxy "node-sass-taobao" "https://npm.taobao.org/mirrors/node-sass/"
    nexus_raw_proxy "node-sass-official" "https://github.com/sass/node-sass/releases/"
    nexus_raw_group "node-sass" "node-sass-taobao,node-sass-official"
    nexus_raw_hosted "mvnsite"
    nexus_raw_hosted "files"

    # see: https://books.sonatype.com/nexus-book/3.0/reference/docker.html
    if [ -z "${NEXUS3_DOCKER_HOSTED_PORT}" ]; then NEXUS3_DOCKER_HOSTED_PORT="5000"; fi
    if [ -z "${NEXUS3_DOCKER_PUBLIC_PORT}" ]; then NEXUS3_DOCKER_PUBLIC_PORT="5001"; fi
    if [ -z "${NEXUS3_DOCKER_PROXY_163_PORT}" ]; then NEXUS3_DOCKER_PROXY_163_PORT="5002"; fi
    if [ -z "${NEXUS3_DOCKER_PROXY_HUB_PORT}" ]; then NEXUS3_DOCKER_PROXY_HUB_PORT="5003"; fi
    nexus_docker_hosted "docker-hosted" "http" "${NEXUS3_DOCKER_HOSTED_PORT}"
    local docker_registries=""
    #docker_registries="${docker_registries},docker-hosted"
    nexus_docker_proxy "docker-central-hub" "http" "${NEXUS3_DOCKER_PROXY_HUB_PORT}" "https://registry-1.docker.io" "HUB"
    docker_registries="${docker_registries},docker-central-hub"
    if [ ! -z "${DOCKER_MIRROR_GCR}" ]; then
        nexus_docker_proxy "docker-mirror-gcr" "http" "5004" "${DOCKER_MIRROR_GCR}" "REGISTRY"
        docker_registries="${docker_registries},docker-mirror-gcr"
    fi
    nexus_docker_proxy "docker-central-163" "http" "${NEXUS3_DOCKER_PROXY_163_PORT}" "http://hub-mirror.c.163.com" "HUB"
    docker_registries="${docker_registries},docker-central-163"
    nexus_docker_group "docker-public" "http" "${NEXUS3_DOCKER_PUBLIC_PORT}" "${docker_registries}"

    # proxy https://registry.npmjs.org, see: https://books.sonatype.com/nexus-book/3.0/reference/npm.html
    nexus_npm_proxy "npm-central-taobao" "https://registry.npm.taobao.org"
    nexus_npm_proxy "npm-central-official" "https://registry.npmjs.org"
    nexus_npm_hosted "npm-hosted"
    nexus_npm_group "npm-public" "npm-hosted,npm-central-taobao,npm-central-official"

    # see: https://books.sonatype.com/nexus-book/3.0/reference/bower.html
    nexus_bower_proxy "bower-central" "http://bower.herokuapp.com"
    nexus_bower_hosted "bower-hosted"
    nexus_bower_group "bower-public" "bower-hosted,bower-central"

    # proxy https://pypi.python.org/pypi, see: https://books.sonatype.com/nexus-book/3.0/reference/pypi.html
    # proxy rubygems.org, see: https://books.sonatype.com/nexus-book/3.0/reference/rubygems.html

    echo "init_nexus done"
}

echo "init_nexus3.sh pwd: $(pwd)"
init_nexus

if [ ! -z "${NEXUS3_PORT}" ] && [ "${NEXUS3_PORT}" != "8081" ]; then
    socat TCP-LISTEN:${NEXUS3_PORT},fork TCP:127.0.0.1:8081 &
fi
