# !/usr/bin/env sh
make .deploy
# Sleep for a bit - i.e. Recommended time from AWS for Windows to come up - 4 minutes
# This has failed a few times, so upping to 5 mins
sleep 360
HOST=$(docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint 'terraform output --json' deploy | jq '.public_ip.value' -rj) \
PASSWORD=$(docker-compose -f deploy.docker-compose.yml -p windows-tomcat-ansible-deploy run --entrypoint 'terraform output --json' deploy | jq '.password.value' -rj) \
docker-compose -f update.docker-compose.yml run update "$@"