#!/bin/sh
git clone https://github.com/hyperledger/composer.git
cd composer/packages/composer-rest-server
npm install
node cli.js
