#!/bin/bash

# imports  
. scripts/envVar.sh
. scripts/utils.sh

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${MAX_RETRY:="5"}
: ${VERBOSE:="false"}

: ${CONTAINER_CLI:="docker"}
: ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}

if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
fi

createChannelGenesisBlock() {
	FABRIC_CFG_PATH=${PWD}/configtx
	if [ ! -d "channel-artifacts" ]; then
	mkdir channel-artifacts
	fi

	which configtxgen
	if [ "$?" -ne 0 ]; then
		fatalln "configtxgen tool not found."
	fi
	set -x
	configtxgen -profile TwoOrgsApplicationGenesis -outputBlock ./channel-artifacts/mychannel.block -channelID mychannel
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannel() {
	setGlobals Sas
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt 5 ] ; do
		sleep 3
		set -x
		# cambiar localhost cuando se haga en varios equipos
		osnadmin channel join --channelID mychannel --config-block ./channel-artifacts/mychannel.block -o orderer.org.com:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		osnadmin channel join --channelID mychannel --config-block ./channel-artifacts/mychannel.block -o orderer2.org.com:8053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER2_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER2_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		osnadmin channel join --channelID mychannel --config-block ./channel-artifacts/mychannel.block -o orderer3.org.com:9053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER3_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER3_ADMIN_TLS_PRIVATE_KEY" >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

# joinChannel ORG
joinChannel() {
  BLOCKFILE="./channel-artifacts/${CHANNEL_NAME}.block"
  FABRIC_CFG_PATH=$PWD/../config/
  ORG=$1
  infoln "org vale ${1}"
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.${ORG} has failed to join channel '$CHANNEL_NAME' "
}

setAnchorPeer() {
  ORG=$1
  # cambiar para cada vez
  ${CONTAINER_CLI} exec peer_sas_cli.1.an0lycfipn5mtziy30yrvow0t ./scripts/setAnchorPeer.sh $ORG mychannel
}

FABRIC_CFG_PATH=${PWD}/configtx