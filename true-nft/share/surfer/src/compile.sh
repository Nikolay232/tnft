#!/bin/bash
set -e

echo "=================================================================================Manager================================================================================="
everdev sol compile Manager.sol

echo "=================================================================================Index================================================================================="
everdev sol compile Index.sol

echo "=================================================================================Data================================================================================="
everdev sol compile Data.sol

echo "=================================================================================NftRoot================================================================================="
everdev sol compile NftRoot.sol

echo "=================================================================================IndexBasis================================================================================="
everdev sol compile IndexBasis.sol

echo "=================================================================================NftDebot================================================================================="
everdev sol compile NftDebot.sol
