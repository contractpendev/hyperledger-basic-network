#!/bin/sh
# cd /home/composer/packages/composer-rest-server/
docker exec $1 cp -r /home/composer/packages/composer-rest-server/ /home/composer/packages/$2/
# Set the base URL in the config file
docker exec -d $1 node /home/composer/packages/$2/cli.js -c admin@$2 -n always -u true -w true -p $3 -b $4 -z $2
#echo "command was"
#echo docker exec -d $1 node /home/composer/packages/composer-rest-server/cli.js -c admin@$2 -n always -u true -w true -p $3 -b $4
