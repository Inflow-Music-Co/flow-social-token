# Inflow Social Token 

## Introduction 

This repository contains the smart contracts and transactions that implement
the core functionality of the Inflow Social Token Platform.

The smart contracts are written in Cadence, a new resource oriented
smart contract programming language designed for the Flow Blockchain.

### What is Inflow Music
Inflow Music is a platform where fans can buy social tokens of their favourite musical artists. 
Fans collect, buy and sell these social tokens, which give them access to exclusive artist content,
experiences, private live streams and more. These social tokens are fungible tokens, not NFTs.

### What is Flow?

Flow is a new blockchain for open worlds. Read more about it [here](https://www.onflow.org/).

### What is Cadence?

Cadence is a new Resource-oriented programming language 
for developing smart contracts for the Flow Blockchain.
Read more about it [here](https://www.docs.onflow.org)

We recommend that anyone who is reading this should have already
completed the [Cadence Tutorials](https://docs.onflow.org/cadence) 
so they can build a basic understanding of the programming language.

Resource-oriented programming, and by extension Cadence, 
is the perfect programming environment for Non-Fungible Tokens (NFTs), because users are able
to store their NFT objects directly in their accounts and transact
peer-to-peer. Please see the [blog post about resources](https://medium.com/dapperlabs/resource-oriented-programming-bee4d69c8f8e)
to understand why they are perfect for digital assets like NBA Top Shot Moments.

### Contributing

If you see an issue with the code for the contracts, the transactions, scripts,
documentation, or anything else, please do not hesitate to make an issue or
a pull request with your desired changes. This is an open source project
and we welcome all assistance from the community!

## Fungible Token Standard
The Social Token contract utilizes [Flow Fungible Token Standard](https://github.com/onflow/flow-ft)
which is equivalent to ERC20 in Solidity. 

### Social Token Contract 
The Social Token uses the Fungible Token interface and functionality but extends it with additional functions. These functions allow any users to mint or burn the social tokens, increasing or decreasing the circulating supply, stores some data in a struct about the Social Token, allows it to accept and deposit fUSD Vaults to users minting and burning and allows it to be maintained by the Controller contract. 

The Social Token is simply a fungible token at its core, free to be exchanged, traded and utlizied on the public Flow Network. 

### Controller Contract 
The Controller contract contains functions that are mostly acceseible only by the admin. These functions allow the admin to mint new Social Tokens, keep track of data related to all the Social Tokens and individual Social Tokens, give capabailities to users and set the FeeStructure, which determines the fee split percentages when a user mints new Socal Tokens. 

## Directory Structure

The directoties here are organised into, contracts, scripts, transactions, unit tests and taskss. 

- `contracts/` Contracts contain the source code for the Inflow Social Token contracts that are deployed to Flow. 

- `scripts/` Scripts contain read-only transactions to get information about the state of a particlar Social Token or a users balance of those Social Tokens. 

- `transactions/` Transactions contain the transactions that admins and users can use to perform actions in the smart contract like minting, burning, registering tokens and transferring tokens. 

- `tasks/` Tasks are written in Golang and use the go-with-the-flow testing and development environment for Flow. The Tasks run various scenarios and intergration tests relating to possible and common user-stories when interacting with the contracts.

 -`test/` Unit tests are written in javascript and they can be ran by following the `README.md` inside `test/js`

N.B Since this repository was completed a later version of go-with-the-flow has been published called overflow. This is recommended for newer projects. For more information on setting up this project in go-with-the-flow please read the section below. 

This project is bootstrapped with Go With The Flow, for easier testing and development. 

[![Coverage Status](https://coveralls.io/repos/github/bjartek/go-with-the-flow/badge.svg?branch=main)](https://coveralls.io/github/bjartek/go-with-the-flow?branch=main) [![ci](https://github.com/bjartek/go-with-the-flow/actions/workflows/test.yml/badge.svg)](https://github.com/bjartek/go-with-the-flow/actions/workflows/test.yml)

# Go with the Flow

Set of go scripts to make it easer to run a Story consisting of creating accounts, deploying contracts, executing transactions and running scripts on the Flow Blockchain.

Feel free to ask questions to @bjartek in the Flow Discord.

v2 of GoWithTheFlow removed a lot of the code in favor of `flowkit` in the flow-cli. Some of the code from here was
contributed by me into flow-cli like the goroutine based event fetcher.

Breaking changes between v1 and v2:
 - v1 had a config section for discord webhooks. That has been removed since the flow-cli will remove extra config things in flow.json. Store the webhook url in an env variable and use it as argument when creating the DiscordWebhook struct.

Special thanks to @sideninja for helping me get my changes into flow-cli. and for jayShen that helped with fixing some issues!

## Usage
First create a project directory, initialize the go module and install go-with-the-flow, (a flow.json config has already been created):

```
go mod init example.com/test-gwtf
go get github.com/bjartek/go-with-the-flow/v2/gwtf
```

Then mint fusd by running the .go task
```
make mint-fusd
```
You will see outputted a list of all events, deployments and scripts run during that task. 

In your tasks, you can build flows of transactions and user behaviour to test your flow contracts. Build your own tasks by adding to the `/tasks` file. Add this task to your Makefile and run 
```
make <taskName>
```

## Main features
 - Create a single go file that will start emulator, deploy contracts, create accounts and run scripts and transactions. see `tasks/main.go` 
 - Fetch events, store progress in a file and send results to Discord. see `examples/event/main.go`
 - Support inline scripts if you do not want to sture everything in a file when testing 
 - Supports writing tests against transactions and scripts with some limitations on how to implement them. 
 - Asserts to make it easier to use the library in writing tests see `examples/transaction_test.go` for examples

## Gotchas
 - When specifying extra accounts that are created on emulator they are created in alphabetical order, the addresses the emulator assign is always fixed. 
 - tldr; Name your stakeholder acounts in alphabetical order

## Examples

In order to run the demo example you only have to run `make` in the example folder of this project
The emulator will be run in memory. 

## Inflow Social Token Overview

Each Social Token registered through the controller contract by an admin must be initialised with the following data 

```cadence
 pub struct TokenStructure {
        pub var tokenId: String
        pub var symbol: String
        pub var issuedSupply: UFix64
        pub var maxSupply: UFix64
        pub var artist: Address
        pub var slope: UFix64
        pub var feeSplitterDetail: {Address: FeeStructure}
        pub var reserve: UFix64
        pub var tokenResourceStoragePath: StoragePath
        pub var tokenResourcePublicPath: PublicPath
        pub var socialMinterStoragePath: StoragePath
        pub var socialMinterPublicPath: PublicPath
        pub var socialBurnerStoragePath: StoragePath
        pub var socialBurnerPublicPath: PublicPat
 }

```

Once a Social Token has been registered, a new Social Token has been created and can be minted or burned by users with that capability to increment or decrement its supply. Tokens can be minted by users depositing FUSD into a collateral pool, which increases the `reserve` value. Tokens can be burned where FUSD from the collateral pool is returned to the user for a profit or loss and decreases the `reserve` value. 

If a user wants to mint new tokens the transaction code calls `getMintPrice(_ tokenId: String, _ amount: UFix64)`. This function returns the quote or the cost to mint new social tokens based on the reserve and criculating supply. It uses a bonding curve formula to calculate the price. 

The bonding curve we are using is based on Bancor's [Bonding Curve Token](https://billyrennekamp.medium.com/converting-between-bancor-and-bonding-curve-price-formulas-9c11309062f5)  

This creates a Dynamic Bonding Curve that reacts to supply and demand by using a constant called Conector Weight, which can be calculated like so: 

`CW = collateral / marketCap`

Furthermore: 

```
marketCap = price * tokenSupply
price = collateral / (tokenSupply * CW)
```

The following functions can be used to calculate the returns when buying and selling tokens:
```
buyAmt = tokenSupply * ((1 + amtPaid / collateral)^CW — 1)
sellAmt = collateral * ((1 + tokensSold / totalSupply)^(1/CW) — 1)
```
To quote the 2018 article by Billy Rennekamp linked above 
_'The interesting part of this method is that while the CW defines a family of curves, it does not define the exact slope of that curve. Instead, the values for tokenSupply and collateral ultimately effect the slope. This makes it possible to have a dynamic price curve that adjusts to inflation and deflation of a token.'_

## Social Token Events 
The smart contract and its various resources will emit certain events that show when specific actions are taken, like minting or burning a Social Token. This is a list of events that can be emitted and what each event means. 

 - `pub event TokensInitialized(initialSupply: UFix64)`
    
    This event is emitted when new Social Tokens are registered


 - `pub event TokensWithdrawn(amount: UFix64, from: Address?)`
    
    This event is emitted when Social Tokens are withdrawn from a user's wallet

 - `pub event TokensDeposited(amount: UFix64, to: Address?)` 
    
    This event is emitted Social Tokens are deposited to a user's wallet. 

 - `pub event TokensMinted(_ tokenId: String, _ mintPrice: UFix64, _ amount: UFix64)`

    This event is emitted when Social Tokens are minted, it also emits the mintPrice for the amount minted.

 - `pub event TokensBurned(_ tokenId: String, _ burnPrice: UFix64, _ amount: UFix64)`
    
    This event is emitted when Social Tokens are burned, it also emits the burnPrice for the amount burned. 

-  `pub event SingleTokenMintPrice(_ tokenId: String, _ mintPrice: UFix64)`

    This event is emitted when Social Tokens are minted, but it emits the price of a single token in all cases. This means it is always easy to index the price of a single social token. 

-   `pub event SingleTokenBurnPrice(_ tokenId: String, _ burnPrice: UFix64)`

    This event is emitted when Social Tokens are burned, it emits the price of a single burned token in all cases. 

## Controller Events

- `pub event incrementReserve(_ newReserve:UFix64)`

    This event is emitted when a token's FUSD reserve is incremented

- `pub event decrementReserve(_ newReserve:UFix64)`

    This event is emitted when a token's FUSD reserce decremented 

- `pub event incrementIssuedSupply(_ amount: UFix64)`

    This event is emitted when the Issued Supply, which is set when registered a token is incremented by admin (rare cases).

- `pub event decrementIssuedSupply(_ amount: UFix64)`

    This event is emitted when the Issued Supply is decremented by admin (rare cases).

- `pub event pub event registerToken(_ tokenId: String, _ symbol: String, _ maxSupply: UFix64, _ artist: Address)` 

    This event is emitted with a new Social Token is registered by the admin. 

- `pub event updatePercentage(_ percentage: UFix64)`
    
    This event is emitted when the feeSplitter for a social token is updated. 

The works in this repository are under the Unlicence

# deployments
Both contracts are deployed to the testnet address ``0x68b2f4c310f8716c``




