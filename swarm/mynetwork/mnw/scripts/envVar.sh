#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
. scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/org.com/tlsca/tlsca.org.com-cert.pem
export PEER0_SAS_CA=${PWD}/organizations/peerOrganizations/sas.org.com/tlsca/tlsca.sas.org.com-cert.pem
export PEER0_QUIRON_CA=${PWD}/organizations/peerOrganizations/quiron.org.com/tlsca/tlsca.quiron.org.com-cert.pem
export PEER0_HLA_CA=${PWD}/organizations/peerOrganizations/hla.org.com/tlsca/tlsca.hla.org.com-cert.pem
export PEER0_VIAMED_CA=${PWD}/organizations/peerOrganizations/viamed.org.com/tlsca/tlsca.viamed.org.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/org.com/orderers/orderer.org.com/tls/server.crt
export ORDERER2_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/org.com/orderers/orderer2.org.com/tls/server.crt
export ORDERER3_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/org.com/orderers/orderer3.org.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/org.com/orderers/orderer.org.com/tls/server.key
export ORDERER2_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/org.com/orderers/orderer2.org.com/tls/server.key
export ORDERER3_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/org.com/orderers/orderer3.org.com/tls/server.key

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ "$USING_ORG" = "Sas" ] || [ "$USING_ORG" = "sas" ]; then
    export CORE_PEER_LOCALMSPID="SasMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_SAS_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/sas.org.com/users/Admin@sas.org.com/msp
    export CORE_PEER_ADDRESS=peer0.sas.org.com:7051
  elif [ "$USING_ORG" = "Quiron" ] || [ "$USING_ORG" = "quiron" ]; then
    export CORE_PEER_LOCALMSPID="QuironMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_QUIRON_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/quiron.org.com/users/Admin@quiron.org.com/msp
    export CORE_PEER_ADDRESS=peer0.quiron.org.com:9051

  elif [ "$USING_ORG" = "Hla" ] || [ "$USING_ORG" = "hla" ]; then
    export CORE_PEER_LOCALMSPID="HlaMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_HLA_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/hla.org.com/users/Admin@hla.org.com/msp
    export CORE_PEER_ADDRESS=peer0.hla.org.com:11051

  elif [ "$USING_ORG" = "Viamed" ] || [ "$USING_ORG" = "viamed" ]; then
    export CORE_PEER_LOCALMSPID="ViamedMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_VIAMED_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/viamed.org.com/users/Admin@viamed.org.com/msp
    export CORE_PEER_ADDRESS=peer0.viamed.org.com:13051    
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}

# Set environment variables for use in the CLI container
setGlobalsCLI() {
  setGlobals $1

  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  if [ "$USING_ORG" = "Sas" ]; then
    export CORE_PEER_ADDRESS=peer0.sas.org.com:7051
  elif [ "$USING_ORG" = "Quiron" ]; then
    export CORE_PEER_ADDRESS=peer0.quiron.org.com:9051
  elif [ "$USING_ORG" = "Hla" ]; then
    export CORE_PEER_ADDRESS=peer0.hla.org.com:11051
  elif [ "$USING_ORG" = "Viamed" ]; then
    export CORE_PEER_ADDRESS=peer0.viamed.org.com:13051    
  else
    errorln "ORG Unknown"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.$1"
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_${1^^}_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
