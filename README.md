# 🍷 ERC4626-SY Contracts

This is a standalone repo for the creation of SY tokens for Sommelier Cellars. Sommelier Cellars are ERC4626 Vaults, and so ERC4626 agnostic SY contracts were created `ERC4626SY.sol` and accompanying dependencies/parent contracts.

---

## **✨🪙 ERC4626SY Contract Details**

The `ERC4626SY.sol` contract is created to provide any target `ERC4626 Vault` the necessary `SY` wrapper contract required to be part of the Pendle protocol architecture.

Vaults can use the `ERC4626SY.sol` as it is, or can override functionality (via inheritance) whilst maintaining the required function signatures and other Pendle `SY` requirements. Functions are made purposely to be overwritten for any custom logic for particular vaults. An example of this pattern in use is the `RyeSY.sol` contract that ultimately inherits the `ERC4626SY.sol` contract and overrides with necessary logic for its own operation.

As well, the source of pricing for each `ERC4626SY.sol` may differ. The Sommelier protocol currently uses a `ERC4626SharePriceOracle` (audited code found [here](https://github.com/PeggyJV/cellar-contracts/blob/main/src/base/ERC4626SharePriceOracle.sol)) although if the oracle is deemed unsafe (see contract for more details), then manual calculation of the exchangeRate is carried out (using total assets and total shares).

> 🚨 Please note, this repo is still under development and the code is not ready, tested, or audited. See active project tasks for most up to date areas of focus. Current stage is coordination with Pendle community on next steps and iteration of the codebase.

💬 Feel free to open up any issues as you see fit!

**Open Discussion Points to Work Through w/ Pendle Protocol**

1. This repo uses SolmateMath as an explicit import, which can be a bit touchy and Pendle may not like that. If they don't, then we can rework the math using their libs.

2. IERC4626 is brought in just from OZ. If they have better ways of importing it that are kosher with their repo setup we can adjust.