#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

ROOTDIR=$(cd "$(dirname "$0")" && pwd)
export PATH=${ROOTDIR}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

# push to the required directory & set a trap to go back if needed
pushd ${ROOTDIR} > /dev/null
trap "popd > /dev/null" EXIT

. scripts/utils.sh

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

function registerEnroll() {
  . organizations/fabric-ca/registerEnroll.sh

  infoln "Creating Hla Identities"

  createHla

}

function installCC() {
  . scripts/ccutils.sh 
  infoln "Installing chaincode"
  installChaincode Hla
}

function networkDown() {

  COMPOSE_FILES_HLA="-f compose/compose-ca-hla.yaml -f compose/docker/docker-compose-ca.yaml -f compose/compose-net-couch-hla.yaml -f compose/docker/docker-compose-couch.yaml -f compose/docker/docker-compose-net-hla.yaml"

  DOCKER_SOCK=$DOCKER_SOCK ${CONTAINER_CLI_COMPOSE} ${COMPOSE_FILES_HLA}  down --volumes --remove-orphans

}

# # Get docker sock path from environment variable
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

# # Parse commandline args

# ## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi

# Determine mode of operation
if [ "$MODE" == "registerEnroll" ]; then
  registerEnroll

elif [ "$MODE" == "installCC" ]; then
  installCC

elif [ "$MODE" == "networkDown" ]; then
  networkDown
  docker service rm $(docker service ls -q)
  docker rm -f $(docker ps -a -q)
  docker system prune --volumes -f
  docker swarm leave --force

else
  printHelp
  exit 1
fi