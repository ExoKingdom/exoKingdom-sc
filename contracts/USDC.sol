// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFarmCoin.sol";
import "./interfaces/IERC20Permit.sol";
import "./types/ERC20Permit.sol";
import "./types/FarmCoinAccessControlled.sol";

contract USDC is ERC20Permit, IFarmCoin, FarmCoinAccessControlled {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(
        address _authority
    )
        ERC20("USDC", "USDC", 6)
        ERC20Permit("USDC")
        FarmCoinAccessControlled(IFarmCoinAuthority(_authority))
    {}

    function mint(
        address account_,
        uint256 amount_
    ) external override onlyGovernor {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) external override {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) internal {
        uint256 decreasedAllowance_ = allowance(account_, msg.sender).sub(
            amount_,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}
