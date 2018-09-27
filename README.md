
# docker-nexus3
An auto configured nexus3

Default admin username/password is: admin/admin123
Default deploy (in maven's settings.xml) username/password is: deployment/deployment

Do not use NFS on nexus3.

## I. Nexus3 Without SSL (http)

Environment variables

  Local nexus3 can set up a company's private nexus2 or nexus3 as upstream

    export INFRASTRUCTURE_INTERNAL_NEXUS2=<http://nexus2:28081>
  or
    export INFRASTRUCTURE_INTERNAL_NEXUS3=<http://nexus3:28081>

Build

    docker-compose build

Start

    docker-compose up -d

## II. Enable SSL (https)

see: https://books.sonatype.com/nexus-book/3.0/reference/security.html#ssl-inbound
see: http://www.eclipse.org/jetty/documentation/current/configuring-ssl.html

### 1. Using Let's encrypt certificates (certbot)

```
git clone https://github.com/certbot/certbot
cd certbot
./certbot-auto --help
./certbot-auto certonly -a standalone \
    -d ${NEXUS3_DOMAIN} \
    -d docker-mirror.${NEXUS3_DOMAIN} \
    -d docker-registry.${NEXUS3_DOMAIN} \
    -d fileserver.${NEXUS3_DOMAIN} \
    -d git.${NEXUS3_DOMAIN} \
    -d maven-site.${NEXUS3_DOMAIN} \
    -d nexus2.${NEXUS3_DOMAIN} \
    -d nexus3.${NEXUS3_DOMAIN} \
    -d node.${NEXUS3_DOMAIN} \
    -d npm.${NEXUS3_DOMAIN} \
    -d sonar.${NEXUS3_DOMAIN} \
    -d www.${NEXUS3_DOMAIN}
ls -la /etc/letsencrypt/live/${NEXUS3_DOMAIN}
```
If pip error, see: https://blog.yzgod.com/setuptools-pkg-resources-pip-wheel-failed
If unsupported locale setting error, see: https://blog.yzgod.com/pip-unsupported-locale-setting
Or use docker image https://hub.docker.com/r/pierreprinetti/certbot/

#### 1.1 Renew https cert
```
# test
sudo certbot renew --dry-run
# 
certbot renew
```

### 2. Using a reverse proxy server
see: https://help.sonatype.com/repomanager3/installation/run-behind-a-reverse-proxy

### 3. Using self signed certificates and configure the repository manager itself to serve HTTPS directly
see: https://support.sonatype.com/hc/en-us/articles/217542177-Using-Self-Signed-Certificates-with-Nexus-Repository-Manager-and-Docker-Daemon
see: https://help.sonatype.com/repomanager3/security/configuring-ssl#ConfiguringSSL-InboundSSL-ConfiguringtoServeContentviaHTTPS

```bash
keytool -keystore keystore -alias jetty -genkeypair -keyalg RSA \
-storepass changeit -keypass changeit -keysize 2048 -validity 5000 \
-dname "CN=*.${NEXUS3_DOMAIN}, OU=Example, O=Sonatype, L=Unspecified, ST=Unspecified, C=US" \
-ext "SAN=DNS:${NEXUS3_DOMAIN},IP:${NEXUS_IP_ADDRESS}" -ext "BC=ca:true" \

keytool -keystore keystore -alias jetty -genkey -keyalg RSA -sigalg SHA256withRSA -ext 'SAN=dns:jetty.eclipse.org,dns:*.jetty.org'
```

## III. Use as a file server

Upload file
```bash
curl --user "${username}:${passwrod}" -T localfile.tar.gz http://fileserver.infra.top/anypath/file.tar.gz
```

## IV. Use as Docker registry and mirror

Issue: Must login (even read only access) before use.
see: [add anonymous read access support for docker repositories](https://issues.sonatype.org/browse/NEXUS-10813)

Login

    #docker login -u deployment -p deployment nexus3
    docker login -u deployment -p deployment nexus3:5000
    docker login -u deployment -p deployment nexus3:5002
    docker login -u deployment -p deployment nexus3:5003
    cat ~/.docker/config.json

    docker search nexus3:5000/alpine
    docker pull nexus3:5000/alpine
    docker tag nginx:1.11.5-alpine nexus3:5000/nginx:1.11.5-alpine
    docker push nexus3:5000/nginx:1.11.5-alpine
    
    # Test docker mirror of gcr.io
    docker pull nexus3:5001/google_containers/kube-dnsmasq-amd64:1.4
    curl http://nexus3:5001/v2/_catalog
    curl http://nexus3:5001/v2/google_containers/kube-dnsmasq-amd64/tags/list

## V. Use as npm registry:

    npm config set registry http://nexus3:28081/nexus/repository/npm-public/
    npm config set cache ${HOME}/.npm/.cache/npm
    npm config set disturl http://nexus3:28081/nexus/repository/npm-dist/
    npm config set sass_binary_site http://nexus3:28081/nexus/repository/npm-sass/

cat or edit '~/.npmrc':

    registry = http://localhost:8081/nexus/repository/npm-public/

Publish into registry

    npm login --registry=http://nexus3:28081/nexus/repository/npm-hosted/
    npm --loglevel info install -g bower
    npm publish --registry http://nexus3:28081/nexus/repository/npm-hosted/
    or "publishConfig" : {"registry" : "http://nexus3:28081/nexus/repository/npm-hosted/"},
    npm deprecate --registry http://nexus3:28081/nexus/repository/npm-hosted/ testproject1@0.0.1 "This package is deprecated"

## VI. Use as bower registry:

    npm install -g bower && npm install -g bower-nexus3-resolver

projectRoot/.bowerrc

    {
    "registry" : {
      "search" : [ "http://nexus3:28081/nexus/repository/bower-public" ],
      "register" : "http://nexus3:28081/nexus/repository/bower-hosted"
    },
    "resolvers" : [ "bower-nexus3-resolver" ],
    "nexus" : {"username" : "deployment","password" : "deployment"}
    }

projectRoot/package.json

    "devDependencies" : {"bower-nexus3-resolver" : "*"}

    bower install jquery
    bower register example-package git://gitserver/project.git
    bower install example-package

## VII. LDAP

1. Make sure DNS is ok, LDAP server is accessible from nexus3.

2. LDAP connection

![](src/site/markdown/images/nexus3-01.png)

3. LDAP user and group

![](src/site/markdown/images/nexus3-02.png)

## VIII. References

see: https://github.com/clearent/nexus
see: https://github.com/sonatype/docker-nexus3/blob/master/Dockerfile
see: http://www.sonatype.org/nexus/2015/09/22/docker-and-nexus-3-ready-set-action/
see: http://codeheaven.io/using-nexus-3-as-your-repository-part-3-docker-images/

## Fix database

```bash

see: https://stackoverflow.com/questions/42951710/orientdb-corruption-state-in-nexus-repository-version-3-2-0-01

/opt/jdk1.8.0_181/bin/java -jar /opt/sonatype/nexus/lib/support/nexus-orient-console.jar
CONNECT PLOCAL:/nexus-data/db/component admin admin

REBUILD INDEX *
export database component-export
drop database
#create database /nexus-data/db/component
CREATE DATABASE PLOCAL:/nexus-data/db/component
import database component-export.json.gz

REBUILD INDEX *
REPAIR DATABASE --fix-graph
REPAIR DATABASE --fix-links
REPAIR DATABASE --fix-ridbags
REPAIR DATABASE --fix-bonsai
DISCONNECT

```

## TODO

Use the official REST API to interact with nexus3

see: http://books.sonatype.com/nexus-book/reference3/scripting.html
