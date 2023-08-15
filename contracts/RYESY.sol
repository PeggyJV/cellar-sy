// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import "@pendle/core-v2/contracts/core/StandardizedYield/SYBase.sol";

// import "./interfaces/ISwETH.sol";

interface IERC4626 {
    function deposit(
        uint256 amount,
        address receiver
    ) external returns (uint256 shares);

    function transfer(address to, uint256 amount) external;
}

interface SharePriceOracle {
    function getLatest()
        external
        view
        returns (
            uint256 answer,
            uint256 timeWeightedAverageAnswer,
            bool isNotSafeToUse
        );
}

contract RYESY is SYBase {
    using Math for uint256;

    address public immutable rye;
    address public immutable WETH;
    SharePriceOracle public spo;

    constructor(
        string memory _name,
        string memory _symbol,
        address _rye,
        address _weth
    ) SYBase(_name, _symbol, _rye) {
        //TODO should this be RYE it was _sweth
        rye = _rye;
        WETH = _weth;
    }

    function setSPO(address newSPO) external onlyOwner {
        spo = SharePriceOracle(newSPO);
        // event
    }

    /*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

    function _deposit(
        address tokenIn,
        uint256 amountDeposited
    ) internal virtual override returns (uint256 /*amountSharesOut*/) {
        if (tokenIn == NATIVE) {
            // WETH.deposit{value: amountDeposited}();
        }

        return IERC4626(rye).deposit(amountDeposited, address(this));
    }

    function _redeem(
        address receiver,
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal virtual override returns (uint256 /*amountTokenOut*/) {
        _transferOut(rye, receiver, amountSharesToRedeem);
        return amountSharesToRedeem;
    }

    /*///////////////////////////////////////////////////////////////
                               EXCHANGE-RATE
    //////////////////////////////////////////////////////////////*/

    function exchangeRate() public view virtual override returns (uint256) {
        // return ISwETH(swETH).getRate();
    }

    /*///////////////////////////////////////////////////////////////
                MISC FUNCTIONS FOR METADATA
    //////////////////////////////////////////////////////////////*/

    function _previewDeposit(
        address tokenIn,
        uint256 amountTokenToDeposit
    ) internal view override returns (uint256 /*amountSharesOut*/) {
        // return rye.previewDeposit(amountTokenToDeposit);
    }

    function _previewRedeem(
        address /*tokenOut*/,
        uint256 amountSharesToRedeem
    ) internal pure override returns (uint256 /*amountTokenOut*/) {
        return amountSharesToRedeem;
    }

    function getTokensIn()
        public
        view
        virtual
        override
        returns (address[] memory res)
    {
        res = new address[](2);
        res[0] = WETH;
        res[1] = NATIVE;
    }

    function getTokensOut()
        public
        view
        virtual
        override
        returns (address[] memory res)
    {
        res = new address[](1);
        res[0] = rye;
    }

    function isValidTokenIn(
        address token
    ) public view virtual override returns (bool) {
        return token == NATIVE || token == rye;
    }

    function isValidTokenOut(
        address token
    ) public view virtual override returns (bool) {
        return token == rye;
    }

    function assetInfo()
        external
        pure
        returns (AssetType assetType, address assetAddress, uint8 assetDecimals)
    {
        return (AssetType.TOKEN, NATIVE, 18);
    }
}
