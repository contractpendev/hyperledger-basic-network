#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -ev

# Shut down the Docker containers that might be currently running.
docker-compose -p $1 -f docker-compose.yml down
