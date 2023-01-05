# Picardy Protocol

The Artiste Token Factory is a module that allows the creation and tokenization of an artist, their brand, or their work as an ERC20 token on the blockchain. The module contains a mapping of ArtisteToken contracts and their details, as well as a struct called RoyaltyDetails which holds information about royalties to be paid. The module has functions for creating new ArtisteToken contracts, updating the RoyaltyDetails struct, and getting the address of the ArtisteToken contracts. The module also has events for when new ArtisteToken contracts are created and when the RoyaltyDetails struct is updated. The module has an interface called IArtisteTokenFactory which allows external contracts to interact with it..

Try running some of the following tasks:
```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
