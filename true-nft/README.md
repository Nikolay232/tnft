TrueNFT contracts

## Installation

Install lerna
Use yarn
```
lerna bootstrap
cd .\components\true-nft-core\
yarn compile
```

Install docker
Install tondev
Set latest Sol compiler version
Instal node SE
Run node se

__configure__

create .env
```
NETWORK=LOCAL
MULTISIG_ADDRESS=0:5c5fc54acbd0e5257baec70bfa82665c8bdd56efdb90532558b600a2da933d28
MULTISIG_PUBKEY=2b036b4370ce5e893780a8418c4b7e038c5a1ad16ce9c7148696c3b03b353a4c
MULTISIG_SECRET=f6efab7e66caadcfa466b26c006985dc8cd3c29a411ecca7a576bd72bebba92b
```

Run test

```
yarn test
```