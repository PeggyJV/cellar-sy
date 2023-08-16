// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import "@pendle/core-v2/contracts/core/StandardizedYield/SYBase.sol";
import {IERC4626} from "interfaces/IERC4626.sol";
import {ISharePriceOracle} from "interfaces/ISharePriceOracle.sol";
import {ERC4626SY} from "contracts/ERC4626SY.sol";
import {IWETH} from "@pendle/core-v2/contracts/interfaces/IWETH.sol";

// /** 
//  * @notice Extra interface for RyeSY for `WETH9.sol` access.
//  */
// interface IWETH {
//     function deposit() external payable;
// }

/**
 * @title RYE Vault (Cellar) SY Contract
 * @notice RYE SY Contract in reference to Pendle IStandardizedYield.sol && SYBase.sol guidelines
 * @author crispymangoes, 0xEinCodes
 * @dev ERC4626SY has the base implementation
 * @dev This contract is built upon the base, ERC4626SY, that overrides certain functions as needed in it.
 */
contract RyeSY is ERC4626SY {
    
    /**
     * @notice Emitted when proposed SharePriceOracle does not match the respective ERC4626 vault.
     */
    error RyeSY__ProposedVaultAssetIsNotWETH(address proposedVaultAsset);

    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        string memory _name,
        string memory _symbol,
        address _vaultAddress,
        ISharePriceOracle _sharePriceOracle
    ) ERC4626SY(_name, _symbol, _vaultAddress, _sharePriceOracle) {
        // ensure WETH is the vault
        vault = IERC4626(vaultAddress);
        vaultAssetAddress = vault.asset();
        if(vaultAssetAddress != wethAddress) revert RyeSY__ProposedVaultAssetIsNotWETH(vaultAssetAddress);
    }


    /**
     * @notice Helper that returns amount of shares to be minted, and takes into account native ETH, or tokenIn as WETH
     * @param tokenIn Base asset corresponding to Vault
     * @param amountDeposited Amount of Base Asset to be deposited
     * @return number of shares to be minted within deposit() function
     */
    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == NATIVE) {
            IWETH WETH = IWETH(tokenIn);
            WETH.deposit{value: amountDeposited}();
        }

        // assume it is WETH then
        return IERC4626(vaultAddress).deposit(amountDeposited, address(this));
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the various tokens that are accepted to mint shares
     * @return array that includes native ETH and WETH for RYE
     */
    function getTokensIn()
        public
        view
        virtual
        override
        returns (address[] memory res)
    {
        res = new address[](2);
        res[0] = wethAddress;
        res[1] = NATIVE;
    }

    /**
     * @notice Checks whether token is valid, and considers native ETH
     * @param token that is being checked
     */
    function isValidTokenIn(
        address token
    ) public view virtual override returns (bool) {
        return token == NATIVE || token == vaultAddress;
    }

}
