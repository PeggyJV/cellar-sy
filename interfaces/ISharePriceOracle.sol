// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

interface ISharePriceOracle {
    function getLatest()
        external
        view
        returns (uint256 answer, uint256 timeWeightedAverageAnswer, bool isNotSafeToUse);
}
