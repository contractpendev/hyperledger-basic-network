#!/bin/sh
docker exec -d $1 composer-rest-server -c admin@$2 -n always -u true -w true -p $3
