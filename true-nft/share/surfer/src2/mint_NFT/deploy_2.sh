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

echo "STEP 1. Set debot address"
# genaddr $DEBOT_NAME
DEBOT_ADDRESS=0:11fa5c0c3424e0c4ff1f588e98e15722e74a9aad30835e55d5e6e15257b6a7bf
echo $DEBOT_ADDRESS
#MANAGER_ADDRESS=0:601c742eb582dac63807fbc55839e107075a2aa7b6ea708dc9a80e5fe380a013
#echo $MANAGER_ADDRESS
NFT_ROOT_ADDRESS=0:084f557276917bab6d0ec1cbd23c4eeb7c42d696fb1f4742773a0b2e5d3798a2
echo $NFT_ROOT_ADDRESS

#NftRootCode=$(base64 -w 0 NftRoot.tvc)
DataCode=$(base64 -w 0 Data.tvc)
IndexCode=$(base64 -w 0 Index.tvc)

# echo "Step 2. Sending tokens to address: $DEBOT_ADDRESS"
# giver $DEBOT_ADDRESS

DEBOT_ABI=$(cat $DEBOT_NAME.abi.json | xxd -ps -c 20000)
# DEBOT_ABI=$(cat $DEBOT_NAME.abi.json | base64 -w 0)

#echo "STEP 3. Deploying manager contract"
#$tos --url $NETWORK deploy Manager.tvc "{\"rootCode\":\"$NftRootCode\"}" \
#	--sign NftDebot.keys.json \
#	--abi Manager.abi.json 1>/dev/null

echo "=================================================================================STEP 3. Deploying NftRoot contract================================================================================="
$tos --url $NETWORK deploy NftRoot.tvc "{\"codeIndex\":\"$IndexCode\",\"codeData\":\"$DataCode\",\"name\":\"name\",\"description\":\"description\",\"tokenCode\":\"tokenCode\",\"totalSupply\":100}" \
	--sign NftDebot.keys.json \
	--abi NftRoot.abi.json 1>/dev/null

#echo "Done! Deployed manager with address: $MANAGER_ADDRESS"
echo "Done! Deployed NftRoot with address: $NFT_ROOT_ADDRESS"

echo "STEP 4. Deploying debot contract"

$tos --url $NETWORK deploy $DEBOT_NAME.tvc "{}" \
	--sign $DEBOT_NAME.keys.json \
	--abi $DEBOT_NAME.abi.json 1>/dev/null

echo "=================================================================================setABI================================================================="

$tos --url $NETWORK call $DEBOT_ADDRESS setABI "{\"dabi\":\"$DEBOT_ABI\"}" \
	--sign $DEBOT_NAME.keys.json \
	--abi $DEBOT_NAME.abi.json 1>/dev/null

#echo "=================================================================================setNftRootCode========================================================="
#
#$tos --url $NETWORK call $DEBOT_ADDRESS setNftRootCode "{\"code\":\"$NftRootCode\"}" \
#	--sign $DEBOT_NAME.keys.json \
#	--abi $DEBOT_NAME.abi.json # 1>/dev/null

echo "=================================================================================setNFTRoot========================================================="

$tos --url $NETWORK call $DEBOT_ADDRESS setNFTRoot "{\"addr\":\"$NFT_ROOT_ADDRESS\"}" \
	--sign $DEBOT_NAME.keys.json \
	--abi $DEBOT_NAME.abi.json # 1>/dev/null

echo "=================================================================================setBasisCode==========================================================="

BasisCode=$(base64 -w 0 IndexBasis.tvc)

$tos --url $NETWORK call $DEBOT_ADDRESS setBasisCode "{\"code\":\"$BasisCode\"}" \
	--sign $DEBOT_NAME.keys.json \
	--abi $DEBOT_NAME.abi.json # 1>/dev/null

echo "=================================================================================setDataCode============================================================"

$tos --url $NETWORK call $DEBOT_ADDRESS setDataCode "{\"code\":\"$DataCode\"}" \
	--sign $DEBOT_NAME.keys.json \
	--abi $DEBOT_NAME.abi.json # 1>/dev/null

echo "=================================================================================setIndexCode==========================================================="

$tos --url $NETWORK call $DEBOT_ADDRESS setIndexCode "{\"code\":\"$IndexCode\"}" \
	--sign $DEBOT_NAME.keys.json \
	--abi $DEBOT_NAME.abi.json # 1>/dev/null

#echo "=================================================================================setManager============================================================="
#
#$tos --url $NETWORK call $DEBOT_ADDRESS setManager "{\"addr\":\"$MANAGER_ADDRESS\"}" \
#	--sign $DEBOT_NAME.keys.json \
#	--abi $DEBOT_NAME.abi.json # 1>/dev/null

echo "=================================================================================setContent============================================================="

#Content=$(base64 -w 0 ../tests/surfer@3x.png)
#Content=$(xxd -ps -c 20000 ../../tests/surfer@3x.png)
#
#$tos --url $NETWORK call $DEBOT_ADDRESS setContent "{\"surfContent\":\"$Content\"}" \
#	--sign $DEBOT_NAME.keys.json \
#	--abi $DEBOT_NAME.abi.json # 1>/dev/null


echo "Done! Deployed debot with address: $DEBOT_ADDRESS"
