#!/bin/bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s/\${ORGM}/$6/" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s/\${ORGM}/$6/" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG="sas"
ORGM="Sas"
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/sas.org.com/tlsca/tlsca.sas.org.com-cert.pem
CAPEM=organizations/peerOrganizations/sas.org.com/ca/ca.sas.org.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > ../myapp/ccp/connection-sas.json
#echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > organizations/peerOrganizations/sas.org.com/connection-sas.yaml

ORG="quiron"
ORGM="Quiron"
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/quiron.org.com/tlsca/tlsca.quiron.org.com-cert.pem
CAPEM=organizations/peerOrganizations/quiron.org.com/ca/ca.quiron.org.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > ../myapp/ccp/connection-quiron.json
#echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > organizations/peerOrganizations/quiron.org.com/connection-quiron.yaml

ORG="hla"
ORGM="Hla"
P0PORT=11051
CAPORT=9054
PEERPEM=organizations/peerOrganizations/hla.org.com/tlsca/tlsca.hla.org.com-cert.pem
CAPEM=organizations/peerOrganizations/hla.org.com/ca/ca.hla.org.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > ../myapp/ccp/connection-hla.json
#echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > organizations/peerOrganizations/hla.org.com/connection-hla.yaml

ORG="viamed"
ORGM="Viamed"
P0PORT=13051
CAPORT=10054
PEERPEM=organizations/peerOrganizations/viamed.org.com/tlsca/tlsca.viamed.org.com-cert.pem
CAPEM=organizations/peerOrganizations/viamed.org.com/ca/ca.viamed.org.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > ../myapp/ccp/connection-viamed.json
#echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM $ORGM)" > organizations/peerOrganizations/viamed.org.com/connection-viamed.yaml
