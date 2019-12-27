# !/usr/bin/env sh
make .deploy
# Sleep for a bit - i.e. Recommended time from AWS for Windows to come up - 4 minutes
# This has failed a few times, so upping to 5 mins
sleep 300
HOST=$(make .deploy-output | jq '.public_ip.value' -rj) \
PASSWORD=$(make .deploy-output | jq '.password.value' -rj) \
docker-compose -f update.docker-compose.yml run update "$@"