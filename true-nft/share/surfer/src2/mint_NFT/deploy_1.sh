#!/bin/bash
set -e

if [[ $1 != *".tvc"  ]] ; then
	echo "ERROR: contract file name .tvc required!"
	echo ""
	echo "USAGE:"
	echo "  ${0} FILENAME NETWORK"
	echo "	where:"
	echo "  	FILENAME - required, debot tvc file name"
	echo "  	NETWORK  - optional, network endpoint, default is http://127.0.0.1"
	echo ""
	echo "PRIMER:"
	echo "  ${0} NftDebot.tvc https://net.ton.dev"
	exit 1
fi

DEBOT_NAME=${1%.*} # filename without extension
NETWORK="${2:-http://127.0.0.1}"

#
# This is TON OS SE giver address, correct it if you use another giver
#
# GIVER_ADDRESS=0:b5e9240fc2d2f1ff8cbb1d1dee7fb7cae155e5f6320e585fcc685698994a19a5

# net.ton.dev
# GIVER_ADDRESS=0:2bb4a0e8391e7ea8877f4825064924bd41ce110fce97e939d3323999e1efbb13


# Check if tonos-cli installed
tos=./tonos-cli
if $tos --version > /dev/null 2>&1; then
	echo "OK $tos installed locally."
else
	tos=tonos-cli
	if $tos --version > /dev/null 2>&1; then
    	echo "OK $tos installed globally."
	else
    	echo "$tos not found globally or in the current directory. Please install it and rerun script."
	fi
fi


function giver {
	$tos --url $NETWORK call \
    	--abi ../giver.abi.json \
    	--sign ../giver.keys.json \
    	$GIVER_ADDRESS \
    	sendTransaction "{\"dest\":\"$1\",\"value\":10000000000,\"bounce\":false}" \
    	1>/dev/null
}

function get_address {
	echo $(cat $1.log | grep "Raw address:" | cut -d ' ' -f 3)
}

function genaddr {
	$tos genaddr $1.tvc $1.abi.json --genkey $1.keys.json > $1.log
}

function setaddr {
	$tos genaddr $1.tvc $1.abi.json --setkey NftDebot.keys.json > $1.log
}

echo "Step 1. Calculating debot address"
genaddr $DEBOT_NAME
#setaddr $DEBOT_NAME
DEBOT_ADDRESS=$(get_address $DEBOT_NAME)
echo $DEBOT_ADDRESS

#echo "Step 2. Calculating manager address"
#setaddr Manager
#MANAGER_ADDRESS=$(get_address Manager)
#echo $MANAGER_ADDRESS

echo "Step 2. Calculating NftRoot address"
setaddr NftRoot
NFT_ROOT_ADDRESS=$(get_address NftRoot)
echo $NFT_ROOT_ADDRESS
