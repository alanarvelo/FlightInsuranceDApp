# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (also using Truffle), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`


## Local blockchain
A local Ganache Blockchain needed to test Dapp functionality. To activate run:
`ganache-cli -m "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat" -a 50 -d 1000000 --allonlimitedContractSize` 


## Develop Client

To run truffle tests:

To run test related to the Dapp usability (Operational Status, Airlines, and Passengers) do:
`truffle test ./test/flightSurety.js` or `npm test`

To run test related to the Server (Oracle functionality Status) do:
`truffle test ./test/oracles.js`

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`

## Develop Server

`npm run server`
`truffle test ./test/oracles.js`