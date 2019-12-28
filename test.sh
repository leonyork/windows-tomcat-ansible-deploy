# !/usr/bin/env sh
HOST=$(docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint 'terraform output --json' deploy | jq '.public_ip.value' -rj)
docker run --rm curlimages/curl:7.67.0 -L -m 5 -v http://$HOST:8080/