// SPDX-License-Identifier: MIT

/**
@title Presale
@dev This contract implements a presale mechanism for FarmCoin tokens. Users can buy tokens with Ether during the presale period.
The presale has a limit of 1000 ether worth of tokens to be sold and each user can buy up to 20 tokens. Users can also be whitelisted to buy tokens at a discounted price. 
The presale period is initiated by the contract owner and tokens are transferred to users upon successful purchase. 
This contract inherits from FarmCoinAccessControlled and uses SafeERC20 and IFarmCoin libraries.
*/
pragma solidity 0.8.4;

import "./FUEL_TOKEN.sol";

contract Presale is FarmCoinAccessControlled {
    IFarmCoin public token;
    using SafeERC20 for IFarmCoin;
    uint256 public constant PRESALE_ENTRIES = 1000 ether;
    uint256 private price = 0.000005 ether;
    uint256 private whitelistPrice;
    uint8 private MAX_BUYABLE = 20; // Max buyable per transaction and not per wallet 
    uint256 public saleAmount;
    uint256 public startTime;
    enum STAGES {
        PENDING,
        PRESALE
    }
    STAGES stage = STAGES.PENDING;
    mapping(address => bool) public whitelisted;
    uint256 public whitelistAccessCount;

    constructor(
        address tokenAddress,
        address _authority
    ) FarmCoinAccessControlled(IFarmCoinAuthority(_authority)) {
        token = IFarmCoin(tokenAddress);
        whitelistPrice = (price * 90) / 100; //0,045
    }

    function buy(uint256 _amount) external payable {
        require(stage != STAGES.PENDING, "Presale not started yet.");
        require(
            saleAmount + _amount <= PRESALE_ENTRIES,
            "PRESALE LIMIT EXCEED"
        );
        require(_amount <= MAX_BUYABLE, "BUYABLE LIMIT EXCEED");
        if (whitelisted[msg.sender]) {
            require(msg.value >= whitelistPrice * _amount, "need more money");
        } else {
            require(msg.value >= price * _amount, "need more money");
        }
        //need to re implement the function of locking funcs
        token.safeTransfer(msg.sender, _amount * 1e18);
        saleAmount += _amount;
    }

    function addWhiteListAddresses(
        address[] calldata addresses
    ) external onlyGovernor {
        require(
            whitelistAccessCount + addresses.length <= 500,
            "Whitelist amount exceed"
        );
        for (uint8 i = 0; i < addresses.length; i++)
            whitelisted[addresses[i]] = true;
        whitelistAccessCount += addresses.length;
    }

    function setWhitelistPrice(uint256 rePrice) external onlyGovernor {
        whitelistPrice = rePrice;
    }

    //0.001
    function setPrice(uint256 rePrice) external onlyGovernor {
        price = rePrice;
    }

    function startSale() external onlyGovernor {
        require(stage == STAGES.PENDING, "Not in pending stage.");
        startTime = block.timestamp;
        stage = STAGES.PRESALE;
    }

    function recoverCurrency(uint256 amount) public onlyGovernor {
        bool success;
        IFarmCoinAuthority farmCoinAuthority = IFarmCoinAuthority(authority);
        address vaultaddress = address(farmCoinAuthority.vault());
        (success, ) = payable(vaultaddress).call{value: amount}("");
        require(success);
    }

    function recoverToken(uint256 tokenAmount) public onlyGovernor {
        IFarmCoinAuthority farmCoinAuthority = IFarmCoinAuthority(authority);
        address vaultaddress = address(farmCoinAuthority.vault());
        IFarmCoin(token).safeTransfer(vaultaddress, tokenAmount * 1e18);
    }

}
