#!/usr/bin/env bash

# for nexus:3.2.0

# arguments: comma_separated_list like "maven-releases,maven-snapshots,maven-central"
# returns: list like \"maven-releases\",\"maven-snapshots\",\"maven-central\"
build_list() {
    local list=($(echo "${1}" | sed s/,/\\n/g))
    local result="";
    for element in "${list[@]}"; do
        if [ -z "${result}" ]; then
            result="${result}\"${element}\"";
        else
            result="${result},\"${element}\"";
        fi
    done
    echo "${result}"
}

# arguments: nexus_http_prefix, userId, password
# returns:
nexus_login() {
    rm -f /tmp/NEXUS_COOKIE
    curl -i -X POST \
    -c /tmp/NEXUS_COOKIE \
    -H 'Accept: */*' \
    -H 'Content-Type:application/x-www-form-urlencoded; charset=UTF-8' \
    -H 'X-Nexus-UI: true' \
    -d "username=$(echo -ne ${2} | base64)" \
    -d "password=$(echo -ne ${3} | base64)" \
    "${1}/rapture/session" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, userId, password
# returns:
nexus_user() {
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Role\",
      \"method\": \"create\",
      \"data\": [
        {
          \"version\": \"\",
          \"source\": \"default\",
          \"id\": \"nx-deploy\",
          \"name\": \"nx-deploy\",
          \"description\": \"Dude with deploy permissions\",
          \"privileges\": [
            \"nx-repository-view-*-*-*\"
          ],
          \"roles\": []
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    -H 'X-Nexus-UI: true' \
    "${1}/extdirect" 2>/dev/null > /dev/null

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_User\",
      \"method\": \"create\",
      \"data\": [
        {
          \"userId\": \"${2}\",
          \"version\": \"\",
          \"firstName\": \"${2}\",
          \"lastName\": \"${2}\",
          \"email\": \"${2}@nexus.local\",
          \"password\": \"${3}\",
          \"status\": \"active\",
          \"roles\": [
            \"nx-deploy\"
          ]
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    -H 'X-Nexus-UI: true' \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, repoPolicy, remoteStorageUrl
# returns:
nexus_maven2_proxy() {
    local timeToLive="1440"

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"maven\": {
              \"versionPolicy\": \"${3}\",
              \"layoutPolicy\": \"STRICT\"
            },
            \"proxy\": {
              \"remoteUrl\": \"${4}\",
              \"contentMaxAge\": -1,
              \"metadataMaxAge\": ${timeToLive}
            },
            \"httpclient\": {
              \"blocked\": false,
              \"autoBlock\": true
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"negativeCache\": {
              \"enabled\": true,
              \"timeToLive\": ${timeToLive}
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"authEnabled\": false,
          \"httpRequestSettings\": false,
          \"recipe\": \"maven2-proxy\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, members
# returns:
nexus_maven_group() {
    local members=$(build_list "${3}")

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"update\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"group\": {
              \"memberNames\": [
                ${members}
              ]
            }
          },
          \"name\": \"${2}\",
          \"format\": \"maven2\",
          \"type\": \"group\",
          \"online\": true
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, remoteStorageUrl
# returns:
nexus_raw_proxy() {
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"proxy\": {
              \"remoteUrl\": \"${3}\",
              \"contentMaxAge\": 1440,
              \"metadataMaxAge\": 1440
            },
            \"httpclient\": {
              \"blocked\": false,
              \"autoBlock\": true,
              \"connection\": {
                \"useTrustStore\": false
              }
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": false
            },
            \"negativeCache\": {
              \"enabled\": false,
              \"timeToLive\": 1
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"authEnabled\": false,
          \"httpRequestSettings\": false,
          \"recipe\": \"raw-proxy\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id
# returns:
nexus_raw_hosted() {
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": false,
              \"writePolicy\": \"ALLOW\"
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"recipe\": \"raw-hosted\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, members
# returns:
nexus_raw_group() {
    local members=$(build_list "${3}")
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": false
            },
            \"group\": {
              \"memberNames\": [
                ${members}
              ]
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"recipe\": \"raw-group\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, protocol, port, remoteStorageUrl, index
# returns:
nexus_docker_proxy() {
    local timeToLive="1440"

    local port=""
    if [ "http" == "${3}" ]; then
        port="\"httpPort\": ${4}"
    elif [ "https" == ${3} ]; then
        port="\"httpsPort\": ${4}"
    else
        port="\"httpPort\": 5000"
    fi

    # HUB,CUSTOM(${6}),REGISTRY
    local index=""
    if [ "HUB" == ${6} ]; then
        index="\"indexType\": \"HUB\",\"useTrustStoreForIndexAccess\": false"
    elif [ "CUSTOM" == ${6} ]; then
        index="\"indexType\": \"CUSTOM\",\"indexUrl\": \"${6}\",\"useTrustStoreForIndexAccess\": false"
    else
        index="\"indexType\": \"REGISTRY\""
    fi

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"docker\": {
              ${port},
              \"v1Enabled\": true
            },
            \"proxy\": {
              \"remoteUrl\": \"${5}\",
              \"contentMaxAge\": ${timeToLive},
              \"metadataMaxAge\": ${timeToLive}
            },
            \"dockerProxy\": {
              ${index},
              \"useTrustStoreForIndexAccess\": false
            },
            \"httpclient\": {
              \"blocked\": false,
              \"autoBlock\": true,
              \"connection\": {
                \"useTrustStore\": false
              }
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"negativeCache\": {
              \"enabled\": false,
              \"timeToLive\": 1
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"checkbox-1874-inputEl\": true,
          \"checkbox-1877-inputEl\": true,
          \"authEnabled\": false,
          \"httpRequestSettings\": false,
          \"recipe\": \"docker-proxy\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, protocol, port
# returns:
nexus_docker_hosted() {
    local port=""
    if [ "http" == "${3}" ]; then
        port="\"httpPort\": ${4}"
    elif [ "https" == ${3} ]; then
        port="\"httpsPort\": ${4}"
    else
        port="\"httpPort\": 5000"
    fi

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"docker\": {
              ${port},
              \"v1Enabled\": true
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true,
              \"writePolicy\": \"ALLOW\"
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"checkbox-1255-inputEl\": true,
          \"checkbox-1258-inputEl\": true,
          \"recipe\": \"docker-hosted\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, protocol, port, members
# returns:
nexus_docker_group() {
    local port=""
    if [ "http" == "${3}" ]; then
        port="\"httpPort\": ${4}"
    elif [ "https" == ${3} ]; then
        port="\"httpsPort\": ${4}"
    else
        port="\"httpPort\": 5000"
    fi

    local members=$(build_list "${5}")

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"docker\": {
              ${port},
              \"v1Enabled\": true
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"group\": {
              \"memberNames\": [
                ${members}
              ]
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"checkbox-1558-inputEl\": false,
          \"checkbox-1561-inputEl\": true,
          \"recipe\": \"docker-group\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, remoteStorageUrl
# returns:
nexus_npm_proxy() {
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"proxy\": {
              \"remoteUrl\": \"${3}\",
              \"contentMaxAge\": 1440,
              \"metadataMaxAge\": 1440
            },
            \"httpclient\": {
              \"blocked\": false,
              \"autoBlock\": true,
              \"connection\": {
                \"useTrustStore\": false
              }
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"negativeCache\": {
              \"enabled\": false,
              \"timeToLive\": 1
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"authEnabled\": false,
          \"httpRequestSettings\": false,
          \"recipe\": \"npm-proxy\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id
# returns:
nexus_npm_hosted() {
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true,
              \"writePolicy\": \"ALLOW\"
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"recipe\": \"npm-hosted\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, members
# returns:
nexus_npm_group() {
    local members=$(build_list "${3}")

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"group\": {
              \"memberNames\": [
                ${members}
              ]
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"recipe\": \"npm-group\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, remoteStorageUrl
# returns:
nexus_bower_proxy() {
    local timeToLive="1440"

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"bower\": {
              \"rewritePackageUrls\": true
            },
            \"proxy\": {
              \"remoteUrl\": \"${3}\",
              \"contentMaxAge\": ${timeToLive},
              \"metadataMaxAge\": ${timeToLive}
            },
            \"httpclient\": {
              \"blocked\": false,
              \"autoBlock\": true
            },
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"negativeCache\": {
              \"enabled\": false,
              \"timeToLive\": 1
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"authEnabled\": false,
          \"httpRequestSettings\": false,
          \"recipe\": \"bower-proxy\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id
# returns:
nexus_bower_hosted() {
    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true,
              \"writePolicy\": \"ALLOW_ONCE\"
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"recipe\": \"bower-hosted\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}

# arguments: nexus_http_prefix, id, members
# returns:
nexus_bower_group() {
    local members=$(build_list "${3}")

    curl -i -X POST \
    -b /tmp/NEXUS_COOKIE \
    -H 'Content-Type: application/json' \
    -H 'Accept: */*' \
    -H 'X-Nexus-UI: true' \
    --data-binary "
    {
      \"action\": \"coreui_Repository\",
      \"method\": \"create\",
      \"data\": [
        {
          \"attributes\": {
            \"storage\": {
              \"blobStoreName\": \"default\",
              \"strictContentTypeValidation\": true
            },
            \"group\": {
              \"memberNames\": [
                ${members}
              ]
            }
          },
          \"name\": \"${2}\",
          \"format\": \"\",
          \"type\": \"\",
          \"url\": \"\",
          \"online\": true,
          \"recipe\": \"bower-group\"
        }
      ],
      \"type\": \"rpc\",
      \"tid\": 0
    }
    " \
    "${1}/extdirect" 2>/dev/null > /dev/null
}
