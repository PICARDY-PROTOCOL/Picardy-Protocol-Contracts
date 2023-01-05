## Picardy Protocol

Picardy protocol exposes a number of factories that are used to create the different products offered by the protocol. Also utilizing chainlink keepers for automation and external adapter to bring in realtime music royalty data on chain.
Using the factories is fairly straight forward as each contract exposes an interface to be used with other smart contracts. Another way to use the protocol is with the various contracts ABI (Application binary interface) or both depending on your use case.

# Factories

Picardy Protocol consists of multiple factory contracts, and these provide builders the ability to create complex Dapps as each factory is built like a module that can be added to your application or smart contract.

**Artiste Token Factory:** 
The Artiste Token Factory is a module that allows the creation and tokenization of an artist, their brand, or their work as an ERC20 token on the blockchain. The module contains a mapping of ArtisteToken contracts and their details, as well as a struct called RoyaltyDetails which holds information about royalties to be paid. The module has functions for creating new ArtisteToken contracts, updating the RoyaltyDetails struct, and getting the address of the ArtisteToken contracts. The module also has events for when new ArtisteToken contracts are created and when the RoyaltyDetails struct is updated. The module has an interface called IArtisteTokenFactory which allows external contracts to interact with it..

**Nft Royalty Sale Factory:**
The Nft Royalty Sale Factory smart contract is a module that allows the creation of contracts for the sale of non-fungible tokens (NFTs) with a built-in royalty payment mechanism. The module contains a mapping of NFT royalty sale contracts and their details, as well as a struct called RoyaltyDetails which holds information about royalties to be paid. The module has functions for creating new NFT royalty sale contracts, updating the RoyaltyDetails struct, adding and getting the URI for a royalty, and getting the address of an NFT royalty sale contract. The module also has events for when new NFT royalty sale contracts are created and when the RoyaltyDetails struct is updated. The module has a function to get the address of the party receiving royalties and the address of the LinkToken contract.

**Token Royalty Sale Factory:**
The TokenRoyaltySaleFactory smart contract is a module that allows the creation of contracts for the sale of royalties as ERC20 tokens. The module contains a mapping of TokenRoyaltySale contracts and their details, as well as a struct called RoyaltyDetails which holds information about royalties to be paid. The module has functions for creating new TokenRoyaltySale contracts, updating the RoyaltyDetails struct, and getting the address and details of a TokenRoyaltySale contract. The module also has an interface called ITokenRoyaltySaleFactory which allows external contracts to interact with it, and an event called RoyaltyDetailsUpdated which is emitted when the RoyaltyDetails struct is updated. The module has a function to return the total number of TokenRoyaltySale contracts that have been created.

Try running some of the following tasks:
```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.js
```
