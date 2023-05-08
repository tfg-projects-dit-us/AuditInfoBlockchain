#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0




# default to using Org1
ORG=${1:-Sas}

# Exit on first error, print all commands.
set -e
set -o pipefail

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

ORDERER_CA=${DIR}/mynetwork/organizations/ordererOrganizations/org.com/tlsca/tlsca.org.com-cert.pem
PEER0_SAS_CA=${DIR}/mynetwork/organizations/peerOrganizations/sas.org.com/tlsca/tlsca.sas.org.com-cert.pem
PEER0_QUIRON_CA=${DIR}/mynetwork/organizations/peerOrganizations/quiron.org.com/tlsca/tlsca.quiron.org.com-cert.pem
PEER0_HLA_CA=${DIR}/mynetwork/organizations/peerOrganizations/hla.org.com/tlsca/tlsca.hla.org.com-cert.pem
PEER0_VIAMED_CA=${DIR}/mynetwork/organizations/peerOrganizations/viamed.org.com/tlsca/tlsca.viamed.org.com-cert.pem


if [[ ${ORG,,} == "sas" || ${ORG,,} == "digibank" ]]; then

   CORE_PEER_LOCALMSPID=SasMSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/mynetwork/organizations/peerOrganizations/sas.org.com/users/Admin@sas.org.com/msp
   CORE_PEER_ADDRESS=peer0.sas.org.com:7051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/mynetwork/organizations/peerOrganizations/sas.org.com/tlsca/tlsca.sas.org.com-cert.pem

elif [[ ${ORG,,} == "quiron" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=Quiron2MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/mynetwork/organizations/peerOrganizations/quiron.org.com/users/Admin@quiron.org.com/msp
   CORE_PEER_ADDRESS=peer0.quiron.org.com:9051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/mynetwork/organizations/peerOrganizations/quiron.org.com/tlsca/tlsca.quiron.org.com-cert.pem

elif [[ ${ORG,,} == "hla" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=Hla2MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/mynetwork/organizations/peerOrganizations/hla.org.com/users/Admin@hla.org.com/msp
   CORE_PEER_ADDRESS=peer0.hla.org.com:11051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/mynetwork/organizations/peerOrganizations/hla.org.com/tlsca/tlsca.hla.org.com-cert.pem  
   
elif [[ ${ORG,,} == "viamed" || ${ORG,,} == "magnetocorp" ]]; then

   CORE_PEER_LOCALMSPID=Viamed2MSP
   CORE_PEER_MSPCONFIGPATH=${DIR}/mynetwork/organizations/peerOrganizations/viamed.org.com/users/Admin@viamed.org.com/msp
   CORE_PEER_ADDRESS=peer0.viamed.org.com:13051
   CORE_PEER_TLS_ROOTCERT_FILE=${DIR}/mynetwork/organizations/peerOrganizations/viamed.org.com/tlsca/tlsca.viamed.org.com-cert.pem     

else
   echo "Unknown \"$ORG\", please choose Org1/Digibank or Org2/Magnetocorp"
   echo "For example to get the environment variables to set upa sas shell environment run:  ./setOrgEnv.sh sas"
   echo
   echo "This can be automated to set them as well with:"
   echo
   echo 'export $(./setOrgEnv.sh sas | xargs)'
   exit 1
fi

# output the variables that need to be set
echo "CORE_PEER_TLS_ENABLED=true"
echo "ORDERER_CA=${ORDERER_CA}"
echo "PEER0_SAS_CA=${PEER0_SAS_CA}"
echo "PEER0_QUIRON_CA=${PEER0_QUIRON_CA}"
echo "PEER0_HLA_CA=${PEER0_HLA_CA}"
echo "PEER0_VIAMED_CA=${PEER0_VIAMED_CA}"

echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"

echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
