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

# Obtain CONTAINER_IDS and remove them
# This function is called when you bring a network down
function clearContainers() {
  infoln "Removing remaining containers"
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter label=service=hyperledger-fabric) 2>/dev/null || true
  ${CONTAINER_CLI} rm -f $(${CONTAINER_CLI} ps -aq --filter name='dev-peer*') 2>/dev/null || true
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
# This function is called when you bring the network down
function removeUnwantedImages() {
  infoln "Removing generated chaincode docker images"
  ${CONTAINER_CLI} image rm -f $(${CONTAINER_CLI} images -aq --filter reference='dev-peer*') 2>/dev/null || true
}

function createSwarm() {
  docker swarm init --advertise-addr 172.16.17.11
  docker network create --driver overlay --attachable mynetwork
}

# Create Organizations crypto material using CAs
function createCAOrderer() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  docker stack deploy -c compose/compose-ca-orderer.yaml -c compose/docker/docker-compose-ca.yaml ca_orderer

  while :
  do
    if [ ! -f "organizations/fabric-ca/ordererOrg/tls-cert.pem" ]; then
      sleep 5
    else
      break
    fi
  done
}

function createCASas() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  docker stack deploy -c compose/compose-ca-sas.yaml -c compose/docker/docker-compose-ca.yaml ca_sas

  while :
  do
    if [ ! -f "organizations/fabric-ca/sas/tls-cert.pem" ]; then
      sleep 5
    else
      break
    fi
  done
}

function createCAQuiron() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  docker stack deploy -c compose/compose-ca-quiron.yaml -c compose/docker/docker-compose-ca.yaml ca_quiron

  while :
  do
    if [ ! -f "organizations/fabric-ca/quiron/tls-cert.pem" ]; then
      sleep 5
    else
      break
    fi
  done
}

function createCAHla() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  docker stack deploy -c compose/compose-ca-hla.yaml  -c compose/docker/docker-compose-ca.yaml ca_hla

  while :
  do
    if [ ! -f "organizations/fabric-ca/hla/tls-cert.pem" ]; then
      sleep 5
    else
      break
    fi
  done
}

function createCAViamed() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  infoln "Generating certificates using Fabric CA"
  docker stack deploy -c compose/compose-ca-viamed.yaml -c compose/docker/docker-compose-ca.yaml ca_viamed

  while :
  do
    if [ ! -f "organizations/fabric-ca/viamed/tls-cert.pem" ]; then
      sleep 5
    else
      break
    fi
  done
}

function generateCCP() {
  infoln "Generating CCP files for organizations"
./organizations/ccp-generate.sh
}

function deployComponentsOrderer() {
  DOCKER_SOCK="${DOCKER_SOCK}" docker stack deploy -c compose/compose-net-couch-orderer.yaml -c compose/docker/docker-compose-couch.yaml orderer
}

function deployComponentsSas() {
  DOCKER_SOCK="${DOCKER_SOCK}" docker stack deploy -c compose/compose-net-couch-sas.yaml -c compose/docker/docker-compose-couch.yaml -c compose/docker/docker-compose-net-sas.yaml peer_sas
}

function deployComponentsQuiron() {
  DOCKER_SOCK="${DOCKER_SOCK}" docker stack deploy -c compose/compose-net-couch-quiron.yaml -c compose/docker/docker-compose-couch.yaml -c compose/docker/docker-compose-net-quiron.yaml peer_quiron
}

function deployComponentsHla() {
  DOCKER_SOCK="${DOCKER_SOCK}" docker stack deploy -c compose/compose-net-couch-hla.yaml -c compose/docker/docker-compose-couch.yaml -c compose/docker/docker-compose-net-hla.yaml peer_hla
}

function deployComponentsViamed() {
  DOCKER_SOCK="${DOCKER_SOCK}" docker stack deploy -c compose/compose-net-couch-viamed.yaml -c compose/docker/docker-compose-couch.yaml -c compose/docker/docker-compose-net-viamed.yaml peer_viamed
}

function createGenesis() {
  . scripts/createChannel.sh 

  infoln "Creating Channel Genesis Block"
  createChannelGenesisBlock
}

function createChannel() {
  . scripts/createChannel.sh 

  infoln "Creating Channel"
  createChannel
}

function joinChannelSas() {
  . scripts/createChannel.sh 

  infoln "Joining Channel"
  joinChannel Sas
}

function joinChannelQuiron() {
  . scripts/createChannel.sh 

  infoln "Joining Channel"
  joinChannel Quiron
}

function joinChannelHla() {
  . scripts/createChannel.sh 

  infoln "Joining Channel"
  joinChannel Hla
}

function joinChannelViamed() {
  . scripts/createChannel.sh 

  infoln "Joining Channel"
  joinChannel Viamed
}

function setAnchorPeerSas() {
  . scripts/createChannel.sh 
  setAnchorPeer Sas
}

function setAnchorPeerQuiron() {
  . scripts/createChannel.sh 
  setAnchorPeer Quiron
}

function setAnchorPeerHla() {
  . scripts/createChannel.sh 
  setAnchorPeer Hla
}

function setAnchorPeerViamed() {
  . scripts/createChannel.sh 
  setAnchorPeer Viamed
}

function vendorAndPackageCC() {
  . scripts/ccutils.sh 
  infoln "Vendoring dependencies and packaging chaincode"
  vendorDependencies
  packageChaincode
}

function queryInstalledSas() {
  . scripts/ccutils.sh 
  infoln "Query installed"
  queryInstalled sas
}

function approveSas() {
  . scripts/ccutils.sh 
  infoln "Approve for Sas"
  approveForMyOrg Sas
}

function queryInstalledQuiron() {
  . scripts/ccutils.sh 
  infoln "Query installed"
  queryInstalled quiron
}

function approveQuiron() {
  . scripts/ccutils.sh 
  infoln "Approve for Quiron"
  approveForMyOrg Quiron
}

function queryInstalledHla() {
  . scripts/ccutils.sh 
  infoln "Query installed"
  queryInstalled hla
}

function approveHla() {
  . scripts/ccutils.sh 
  infoln "Approve for Hla"
  approveForMyOrg Hla
}

function queryInstalledViamed() {
  . scripts/ccutils.sh 
  infoln "Query installed"
  queryInstalled viamed
}

function approveViamed() {
  . scripts/ccutils.sh 
  infoln "Approve for Viamed"
  approveForMyOrg Viamed
}

function checkReadinessSas() {
  . scripts/ccutils.sh 
  infoln "Check commit readiness for Sas"
  checkCommitReadiness Sas
}

function checkReadinessQuiron() {
  . scripts/ccutils.sh 
  infoln "Check commit readiness for Quiron"
  checkCommitReadiness Quiron
}

function checkReadinessHla() {
  . scripts/ccutils.sh 
  infoln "Check commit readiness for Hla"
  checkCommitReadiness Hla
}

function checkReadinessViamed() {
  . scripts/ccutils.sh 
  infoln "Check commit readiness for Viamed"
  checkCommitReadiness Viamed
}

function commitDefinition() {
  . scripts/ccutils.sh
  commitChaincodeDefinition Sas Quiron Hla Viamed
}

function queryCommitted() {
  . scripts/ccutils.sh 
  infoln "Finishing chaincode deployment"
  queryCommitted Sas
  queryCommitted Quiron
  queryCommitted Hla
  queryCommitted Viamed
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
if [ "$MODE" == "createSwarm" ]; then
  createSwarm

elif [ "$MODE" == "createCAOrderer" ]; then
  createCAOrderer

elif [ "$MODE" == "createCASas" ]; then
  createCASas

elif [ "$MODE" == "createCAQuiron" ]; then
  createCAQuiron

elif [ "$MODE" == "createCAHla" ]; then
  createCAHla

elif [ "$MODE" == "createCAViamed" ]; then
  createCAViamed

elif [ "$MODE" == "generateCCP" ]; then
  generateCCP

elif [ "$MODE" == "deployComponentsOrderer" ]; then
  deployComponentsOrderer

elif [ "$MODE" == "deployComponentsSas" ]; then
  deployComponentsSas

elif [ "$MODE" == "deployComponentsQuiron" ]; then
  deployComponentsQuiron

elif [ "$MODE" == "deployComponentsHla" ]; then
  deployComponentsHla

elif [ "$MODE" == "deployComponentsViamed" ]; then
  deployComponentsViamed

elif [ "$MODE" == "createGenesis" ]; then
  createGenesis
  
elif [ "$MODE" == "createChannel" ]; then
  createChannel

elif [ "$MODE" == "joinChannelSas" ]; then
  joinChannelSas

elif [ "$MODE" == "joinChannelQuiron" ]; then
  joinChannelQuiron

elif [ "$MODE" == "joinChannelHla" ]; then
  joinChannelHla

elif [ "$MODE" == "joinChannelViamed" ]; then
  joinChannelViamed

elif [ "$MODE" == "setAnchorPeerSas" ]; then
  setAnchorPeerSas

elif [ "$MODE" == "setAnchorPeerQuiron" ]; then
  setAnchorPeerQuiron

elif [ "$MODE" == "setAnchorPeerHla" ]; then
  setAnchorPeerHla

elif [ "$MODE" == "setAnchorPeerViamed" ]; then
  setAnchorPeerViamed

elif [ "$MODE" == "vendorAndPackageCC" ]; then
  vendorAndPackageCC

elif [ "$MODE" == "queryInstalledApproveSas" ]; then
  queryInstalledSas
  approveSas

elif [ "$MODE" == "queryInstalledApproveQuiron" ]; then
  queryInstalledQuiron
  approveQuiron

elif [ "$MODE" == "queryInstalledApproveHla" ]; then
  queryInstalledHla
  approveHla

elif [ "$MODE" == "queryInstalledApproveViamed" ]; then
  queryInstalledViamed
  approveViamed

elif [ "$MODE" == "checkReadinessSas" ]; then
  checkReadinessSas

elif [ "$MODE" == "checkReadinessQuiron" ]; then
  checkReadinessQuiron

elif [ "$MODE" == "checkReadinessHla" ]; then
  checkReadinessHla

elif [ "$MODE" == "checkReadinessViamed" ]; then
  checkReadinessViamed

elif [ "$MODE" == "commitDefinition" ]; then
  commitDefinition

elif [ "$MODE" == "queryCommitted" ]; then
  queryCommitted
  
else
  printHelp
  exit 1
fi