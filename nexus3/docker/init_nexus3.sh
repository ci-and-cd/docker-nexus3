#!/usr/bin/env bash

if [ -z "${NEXUS_HOSTNAME}" ]; then NEXUS_HOSTNAME="nexus3.local"; fi
if [ -z "${NEXUS_ADDRESS}" ]; then NEXUS_ADDRESS="${NEXUS_HOSTNAME}:8081"; fi

init_nexus() {
    if type -p waitforit > /dev/null; then
        #  -debug
        waitforit -full-connection=tcp://${NEXUS_ADDRESS} -timeout=180
        local nexus_running="$?"
        echo "nexus_running: ${nexus_running}"
        if [ ${nexus_running} -gt 0 ]; then
            echo "nexus is not running"
            exit 1
        fi
    fi

    . nexus3_utils.sh

    local nexus_http_prefix=""
    if [ ! -z "${NEXUS_CONTEXT}" ]; then
        nexus_http_prefix="http://${NEXUS_ADDRESS}/${NEXUS_CONTEXT}/service"
    else
        nexus_http_prefix="http://${NEXUS_ADDRESS}/service"
    fi

    # 默认用户名/密码 admin/admin123
    nexus_login "${nexus_http_prefix}" "admin" "admin123"

    # 设置deployment账户密码
    # see: http://stackoverflow.com/questions/40966763/how-do-i-create-a-user-with-the-a-role-with-the-minimal-set-of-privileges-deploy
    # see: https://books.sonatype.com/nexus-book/reference3/security.html#privileges
    if [ -z "${NEXUS_DEPLOYMENT_PASSWORD}" ]; then
        NEXUS_DEPLOYMENT_PASSWORD="deployment"
    fi
    nexus_user "${nexus_http_prefix}" "deployment" "${NEXUS_DEPLOYMENT_PASSWORD}"

    local maven_group_members="maven-releases,maven-snapshots,maven-central"
    # TODO nexus_maven2_hosted "maven-thirdparty" "SNAPSHOT"
    # TODO maven_group_members="${maven_group_members},maven-thirdparty"
    # https://github.com/spring-projects/spring-framework/wiki/Spring-repository-FAQ
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-libs-release" "RELEASE" "http://repo.spring.io/libs-release"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-libs-milestone" "RELEASE" "http://repo.spring.io/libs-milestone"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-libs-snapshot" "SNAPSHOT" "http://repo.spring.io/libs-snapshot"
    maven_group_members="${maven_group_members},spring-libs-release,spring-libs-milestone,spring-libs-snapshot"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-release" "RELEASE" "http://repo.spring.io/release"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-milestone" "RELEASE" "http://repo.spring.io/milestone"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-snapshot" "SNAPSHOT" "http://repo.spring.io/snapshot"
    maven_group_members="${maven_group_members},spring-release,spring-milestone,spring-snapshot"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-libs-release-local" "RELEASE" "http://repo.spring.io/libs-release-local"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-libs-milestone-local" "RELEASE" "http://repo.spring.io/libs-milestone-local"
    nexus_maven2_proxy "${nexus_http_prefix}" "spring-libs-snapshot-local" "SNAPSHOT" "http://repo.spring.io/libs-snapshot-local"
    maven_group_members="${maven_group_members},spring-libs-release-local,spring-libs-milestone-local,spring-libs-snapshot-local"
    # http://conjars.org
    nexus_maven2_proxy "${nexus_http_prefix}" "conjars.org" "RELEASE" "http://conjars.org/repo/"
    maven_group_members="${maven_group_members},conjars.org"
    # https://clojars.org
    nexus_maven2_proxy "${nexus_http_prefix}" "clojars.org" "RELEASE" "https://clojars.org/repo/"
    maven_group_members="${maven_group_members},clojars.org"
    # http://www.codehaus.org/mechanics/maven/
    nexus_maven2_proxy "${nexus_http_prefix}" "codehaus-mule-repo" "RELEASE" "https://repository-master.mulesoft.org/nexus/content/groups/public/"
    maven_group_members="${maven_group_members},codehaus-mule-repo"
    # http://repo.jenkins-ci.org
    nexus_maven2_proxy "${nexus_http_prefix}" "repo.jenkins-ci.org" "RELEASE" "http://repo.jenkins-ci.org/public/"
    maven_group_members="${maven_group_members},repo.jenkins-ci.org"
    # https://developer.jboss.org/wiki/MavenRepository
    nexus_maven2_proxy "${nexus_http_prefix}" "org.jboss.repository" "RELEASE" "https://repository.jboss.org/nexus/content/repositories/public/"
    maven_group_members="${maven_group_members},org.jboss.repository"

    # apache snapshots
    nexus_maven2_proxy "${nexus_http_prefix}" "apache-snapshots" "SNAPSHOT" "https://repository.apache.org/content/repositories/snapshots/"
    maven_group_members="${maven_group_members},apache-snapshots"

    # sonatype
    nexus_maven2_proxy "${nexus_http_prefix}" "sonatype-releases" "RELEASE" "https://oss.sonatype.org/content/repositories/releases/"
    maven_group_members="${maven_group_members},sonatype-releases"
    nexus_maven2_proxy "${nexus_http_prefix}" "sonatype-snapshots" "SNAPSHOT" "https://oss.sonatype.org/content/repositories/snapshots/"
    maven_group_members="${maven_group_members},sonatype-snapshots"

    nexus_maven2_proxy "${nexus_http_prefix}" "github-chshawkn-wagon-maven-plugin" "RELEASE" "https://raw.github.com/chshawkn/wagon-maven-plugin/mvn-repo/"
    maven_group_members="${maven_group_members},github-chshawkn-wagon-maven-plugin"
    nexus_maven2_proxy "${nexus_http_prefix}" "github-chshawkn-maven-settings-decoder" "RELEASE" "https://raw.github.com/chshawkn/maven-settings-decoder/mvn-repo/"
    maven_group_members="${maven_group_members},github-chshawkn-maven-settings-decoder"

    # internal-nexus
    if [[ "${INTERNAL_NEXUS}" == http* ]]; then
        nexus_maven2_proxy "${nexus_http_prefix}" "internal-nexus.snapshot" "SNAPSHOT" "http://nexus2.internal/nexus/content/groups/public/"
        maven_group_members="${maven_group_members},internal-nexus.snapshot"
        nexus_maven2_proxy "${nexus_http_prefix}" "internal-nexus.release" "RELEASE" "http://nexus2.internal/nexus/content/groups/public/"
        maven_group_members="${maven_group_members},internal-nexus.release"
    fi

    nexus_maven_group "${nexus_http_prefix}" "maven-public" "${maven_group_members}"

    # Raw Repositories, Maven Sites and More see: https://books.sonatype.com/nexus-book/3.0/reference/raw.html
    #nexus_raw_proxy "${nexus_http_prefix}" "npm-dist" "https://nodejs.org/dist/"
    # https://npm.taobao.org/dist is same as https://npm.taobao.org/mirrors/node/
    nexus_raw_proxy "${nexus_http_prefix}" "npm-dist-taobao" "https://npm.taobao.org/dist/"
    nexus_raw_proxy "${nexus_http_prefix}" "npm-dist-official" "https://nodejs.org/dist/"
    nexus_raw_group "${nexus_http_prefix}" "npm-dist" "npm-dist-taobao,npm-dist-official"
    nexus_raw_proxy "${nexus_http_prefix}" "npm-sass-taobao" "https://npm.taobao.org/mirrors/node-sass/"
    nexus_raw_proxy "${nexus_http_prefix}" "npm-sass-official" "https://github.com/sass/node-sass/releases/"
    nexus_raw_group "${nexus_http_prefix}" "npm-sass" "npm-sass-taobao,npm-sass-official"
    nexus_raw_hosted "${nexus_http_prefix}" "mvnsite"
    nexus_raw_hosted "${nexus_http_prefix}" "files"

    # see: https://books.sonatype.com/nexus-book/3.0/reference/docker.html
    nexus_docker_hosted "${nexus_http_prefix}" "docker-hosted" "http" "5000"
    nexus_docker_proxy "${nexus_http_prefix}" "docker-central-163" "http" "5002" "http://hub-mirror.c.163.com" "HUB"
    nexus_docker_proxy "${nexus_http_prefix}" "docker-central-hub" "http" "5003" "https://registry-1.docker.io" "HUB"
    nexus_docker_group "${nexus_http_prefix}" "docker-public" "http" "5001" "docker-hosted,docker-central-163,docker-central-hub"

    # proxy https://registry.npmjs.org, see: https://books.sonatype.com/nexus-book/3.0/reference/npm.html
    nexus_npm_proxy "${nexus_http_prefix}" "npm-central-taobao" "https://registry.npm.taobao.org"
    nexus_npm_proxy "${nexus_http_prefix}" "npm-central-official" "https://registry.npmjs.org"
    nexus_npm_hosted "${nexus_http_prefix}" "npm-hosted"
    nexus_npm_group "${nexus_http_prefix}" "npm-public" "npm-hosted,npm-central-taobao,npm-central-official"

    # see: https://books.sonatype.com/nexus-book/3.0/reference/bower.html
    nexus_bower_proxy "${nexus_http_prefix}" "bower-central" "http://bower.herokuapp.com"
    nexus_bower_hosted "${nexus_http_prefix}" "bower-hosted"
    nexus_bower_group "${nexus_http_prefix}" "bower-public" "bower-hosted,bower-central"

    # proxy https://pypi.python.org/pypi, see: https://books.sonatype.com/nexus-book/3.0/reference/pypi.html
    # proxy rubygems.org, see: https://books.sonatype.com/nexus-book/3.0/reference/rubygems.html

    echo "init_nexus done"
}

init_nexus
