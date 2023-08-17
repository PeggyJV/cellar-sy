# 🍷 ERC4626-SY Contracts

This is a standalone repo for the creation of SY tokens for Sommelier Cellars. Sommelier Cellars are ERC4626 Vaults, and so ERC4626 agnostic SY contracts were created `ERC4626SY.sol` and accompanying dependencies/parent contracts.

---

## **✨🪙 ERC4626SY Contract Details**

The `ERC4626SY.sol` contract is created to provide any target `ERC4626 Vault` the necessary `SY` wrapper contract required to be part of the Pendle protocol architecture.

Vaults can use the `ERC4626SY.sol` as it is, or can override functionality (via inheritance) whilst maintaining the required function signatures and other Pendle `SY` requirements. Functions are made purposely to be overwritten for any custom logic for particular vaults. An example of this pattern in use is the `RyeSY.sol` contract that ultimately inherits the `ERC4626SY.sol` contract and overrides with necessary logic for its own operation.

As well, the source of pricing for each `ERC4626SY.sol` may differ. The Sommelier protocol currently uses a `ERC4626SharePriceOracle` although if the oracle is deemed unsafe (see contract for more details), then manual calculation of the exchangeRate is carried out (using total assets and total shares).

> 🚨 Please note, this repo is still under development and the code is not ready, tested, or audited. See active project tasks for most up to date areas of focus. Current stage is coordination with Pendle community on next steps and iteration of the codebase.

💬 Feel free to open up any issues as you see fit!
