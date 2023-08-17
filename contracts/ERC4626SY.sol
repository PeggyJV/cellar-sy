// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;
import "@pendle/core-v2/contracts/core/StandardizedYield/SYBase.sol";
import { IERC4626 } from "interfaces/IERC4626.sol";
import { ISharePriceOracle } from "interfaces/ISharePriceOracle.sol";
import { ERC4626SharePriceOracle } from "contracts/ERC4626SharePriceOracle.sol";
import { SolmateMath } from "./SolmateMath.sol";

/**
 * @title ERC4626 (Cellar) Generic SY Contract
 * @notice Generic SY Contract in reference to Pendle IStandardizedYield.sol && SYBase.sol guidelines
 * @author crispymangoes, 0xEinCodes
 * @dev SharePriceOracle source is upgradeable. Owner is a timelock.
 * @dev This contract serves as a base for ERC4626 contracts to built upon as most functions are virtual and able to be overridden.
 * TODO: we want timelock to be the owner. Add into repo.
 * TODO: rename contract to be ERC4626SY if we really want to advertise this as agnostic
 */
contract ERC4626SY is SYBase {
    using SolmateMath for uint256;

    /**
     * Emitted when proposed SharePriceOracle does not match the respective ERC4626 vault.
     */
    error CellarSY__ProposedSharePriceOracleTargetVaultMismatch(address sharePriceOracle);

    /**
     * Emitted when proposed SharePriceOracle decimals does not match the var ORACLE_DECIMALS.
     */
    error CellarSY__ProposedSharePriceOracleDecimalsMismatch(address sharePriceOracle);

    // vars

    address public immutable vaultAddress;
    address public immutable vaultAssetAddress;
    ERC4626SharePriceOracle public sharePriceOracle;

    /**
     * @notice ERC4626 target vault this contract is an oracle for.
     */
    IERC4626 public immutable vault;

    /**
     * @notice ERC4626 target vault this contract is an oracle for.
     */
    uint8 public immutable TARGET_ASSET_DECIMALS;

    /**
     * @notice The decimals the Cellar is expecting the oracle to have.
     */
    uint8 public constant ORACLE_DECIMALS = 18;

    constructor(
        string memory _name,
        string memory _symbol,
        address _vaultAddress,
        address _sharePriceOracle
    ) SYBase(_name, _symbol, _vaultAddress) {
        //TODO should this be RYE it was _sweth
        vaultAddress = _vaultAddress;
        vault = IERC4626(vaultAddress);
        vaultAssetAddress = vault.asset();

        // TODO: try w/ internal helper, but it will likely not compile because cellarSY is not deployed yet.
        _checkOracleInputs(ERC4626SharePriceOracle(_sharePriceOracle));
        // if(_sharePriceOracle.target() != vault) revert CellarSY__ProposedSharePriceOracleTargetVaultMismatch(address(_sharePriceOracle));

        // if(_sharePriceOracle.decimals() != ORACLE_DECIMALS) revert CellarSY__ProposedSharePriceOracleDecimalsMismatch(address(_sharePriceOracle));

        sharePriceOracle = ERC4626SharePriceOracle(_sharePriceOracle); // this is the sharePriceOracle corresponding to target below
        TARGET_ASSET_DECIMALS = ERC20(vaultAssetAddress).decimals();
    }

    function setSharePriceOracle(address _newSharePriceOracle) external onlyOwner {
        _checkOracleInputs(ERC4626SharePriceOracle(_newSharePriceOracle));
        sharePriceOracle = ERC4626SharePriceOracle(_newSharePriceOracle);
        // event
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal helper that returns amount of shares out to be minted
     * @param tokenIn Base asset corresponding to Vault
     * @param amountDeposited Amount of Base Asset to be deposited
     * @return number of shares to be minted within deposit() function
     */
    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        require(tokenIn == vaultAssetAddress); // TODO: write error statement, not sure if we want a revert though actually.
        return vault.deposit(amountDeposited, address(this));
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 /*amountTokenOut*/) {
        _transferOut(vaultAssetAddress, receiver, amountSharesToRedeem); // transfers shares to be burnt
        return amountSharesToRedeem; // returns to redeem() to continue tx
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get exchange rate or calculate on chain if source is deemed unsafe.
     * @dev asset in accordance to IStandardizedYield is the ERC 4626 base asset. So for RYE, it's wETH. For RYU, is USDC.
     */
    function exchangeRate() public view virtual override returns (uint256) {
        uint256 sharePrice;
        if (address(sharePriceOracle) != address(0)) {
            (, uint256 sharePrice, bool notSafeToUse) = sharePriceOracle.getLatest(); // sharePrice is equivalent to timeWeightedAverageAnswer when pulling from sharePriceOracle source

            // shareprice oracle always gives asset decimals
            if (!notSafeToUse) {
                sharePrice = sharePrice.changeDecimals(ORACLE_DECIMALS, TARGET_ASSET_DECIMALS);
                return sharePrice;
            }
        }

        // manual onchain calculation
        uint256 totalShares = vault.totalSupply();
        // Get total Assets but scale it up to decimals decimals of precision.
        uint256 totalAssets = vault.totalAssets();
        if (totalShares == 0) return 0;
        sharePrice = uint256(10 ** vault.decimals()).mulDivDown(totalAssets, totalShares);

        return sharePrice;
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        return vault.previewDeposit(amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    /**
     * @dev Assumes singular base asset per ERC 4626 is the only token accepted
     */
    function getTokensIn() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = vaultAssetAddress;
    }

    function getTokensOut() public view virtual override returns (address[] memory res) {
        res = new address[](1);
        res[0] = vaultAddress;
    }

    function isValidTokenIn(address token) public view virtual override returns (bool) {
        return token == vaultAssetAddress;
    }

    function isValidTokenOut(address token) public view virtual override returns (bool) {
        return token == vaultAddress;
    }

    // TODO: does this need to be pure?
    function assetInfo()
        external
        view
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, vaultAssetAddress, TARGET_ASSET_DECIMALS);
    }

    function _checkOracleInputs(
        ERC4626SharePriceOracle _sharePriceOracle
    ) internal view virtual returns (bool) {
        if (address(_sharePriceOracle.target()) != address(vault))
            revert CellarSY__ProposedSharePriceOracleTargetVaultMismatch(
                address(_sharePriceOracle)
            );

        if (_sharePriceOracle.decimals() != ORACLE_DECIMALS)
            revert CellarSY__ProposedSharePriceOracleDecimalsMismatch(address(_sharePriceOracle));

        return true;
    }
}
