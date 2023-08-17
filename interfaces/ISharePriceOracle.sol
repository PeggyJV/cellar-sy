// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISharePriceOracle {
    function getLatest()
        external
        view
        returns (uint256 answer, uint256 timeWeightedAverageAnswer, bool isNotSafeToUse);
}
