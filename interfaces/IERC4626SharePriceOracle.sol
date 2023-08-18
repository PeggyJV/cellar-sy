// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;
import { ERC4626 } from "solmate/src/mixins/ERC4626.sol";

/**
 * @title IERC4626SharePriceOracle
 * @author Interface for ERC4626SharePriceOracles agnostic to vaults following the ERC4626 standard.
 */
interface IERC4626SharePriceOracle {
    /**
     * @notice Get the latest answer, time weighted average answer, and bool indicating whether they can be safely used.
     */
    function getLatest()
        external
        view
        returns (uint256 ans, uint256 timeWeightedAverageAnswer, bool notSafeToUse);

    /**
     * @notice Decimals used to scale share price for internal calculations.
     */
    function decimals() external view returns (uint8);

    /**
     * @notice ERC4626 target vault this contract is an oracle for.
     */
    function target() external view returns (ERC4626);
}

// /**
//  * @notice Get the latest answer, and bool indicating whether answer is safe to use or not.
//  */
// function getLatestAnswer() external view returns (uint256, bool) {

// }
