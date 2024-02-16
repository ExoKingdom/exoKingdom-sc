// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Importing SafeMath library to prevent integer overflow errors
import "./libraries/SafeMath.sol";
// Importing SafeERC20 library to prevent errors with ERC20 tokens
import "./libraries/SafeERC20.sol";
// Importing IERC20 interface for interacting with ERC20 tokens
import "./interfaces/IERC20.sol";
// Importing FarmCoin interface for interacting with FarmCoin
import "./interfaces/IFarmCoin.sol";
// Importing IERC20Permit interface for interacting with ERC20 tokens with permit() function
import "./interfaces/IERC20Permit.sol";
// Importing ERC20Permit type for supporting ERC20 tokens with permit() function
import "./types/ERC20Permit.sol";
// Importing FarmCoinAccessControlled type for access control on FarmCoin related functions
import "./types/FarmCoinAccessControlled.sol";

contract DepositContract is FarmCoinAccessControlled {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IFarmCoin;

    // Tokens
    IFarmCoin public immutable FarmCoin; // FarmCoin token contract address
    IERC20 public DepositToken; // ERC20 token contract address

    // Deposit matrix & interest
    // Struct for storing deposit information
    struct Deposit {
        uint256 depositTime; // Timestamp when the deposit was made
        uint256 depositAmount; // Amount of tokens deposited
        uint256 expire; // Timestamp when the deposit expires
        uint256 rewardPerSecond; // Rate of reward tokens per second
        uint256 lastClaimTime; // Timestamp when the last reward was claimed
        string currency; // Currency of the deposited tokens (ETH or USDC)
        address user; // Address of the depositor
        bool isWithdrawn; // Boolean flag to indicate whether the deposit has been withdrawn
    }
    // Mapping for storing the balance of Ether for each address
    mapping(address => uint) public etherBalanceOf;
    // Mapping for storing the deposit start time for each address
    mapping(address => uint) public depositStart;
    // Mapping for storing whether an address has made a deposit
    mapping(address => bool) public isDeposited;
    // Event for depositing Ether
    event DepositETH(address indexed user, uint etherAmount, uint timeStart);
    // Event for withdrawing Ether
    event WithdrawETH(
        address indexed user,
        uint etherAmount,
        uint depositTime,
        uint interest
    );

    mapping(address => Deposit[]) depositorMatrix;
    // Array for storing the interest rate for each duration
    uint256[] public interestArray = [5, 10, 15, 20];

    // Constructor for initializing the contract
    constructor(
        address _FarmCoin,
        address _DepositToken,
        address _authority
    ) FarmCoinAccessControlled(IFarmCoinAuthority(_authority)) {
        // Checking that the FarmCoin token address is not a zero address
        require(_FarmCoin != address(0), "Constructor: Zero address: FarmCoin");
        // Initializing the FarmCoin token address
        FarmCoin = IFarmCoin(_FarmCoin);

        // Checking that the deposit token address is not a zero address
        require(
            _DepositToken != address(0),
            "Constructor: Zero address: DepositToken"
        );
        // Initializing the deposit token address
        DepositToken = IERC20(_DepositToken);
    }

    /**
     @dev Allows a user to deposit tokens and earn rewards for a specified duration.
     @param _amount The amount of tokens to be deposited.
     @param _duration The duration for which the tokens are to be deposited. Must be either 1, 2, 3, or 4 representing 1 day, 2 days, 3 days, or 4 days, respectively.
     */
    function deposit(uint256 _amount, uint256 _duration) external {
        address account = msg.sender;

        require(
            _duration == 1 ||
                _duration == 2 ||
                _duration == 3 ||
                _duration == 4,
            "Deposit: Deposit duration incorrect"
        );

        require(
            DepositToken.balanceOf(account) >= _amount,
            "Deposit: Balance infuluence"
        );
        
        require(depositorMatrix[account].length < 5, "Deposit: Maximum number of stakes reached");

        require(
            _amount >= 100000000, // 100 USDC 
            "Deposit: Amount below minimum requirement"
        );

        uint256 _rewardPerSecond;
        if (_duration == 1) {
            _rewardPerSecond = uint256(5 ** 18).div(1 days);
        } else if (_duration == 2) {
            _rewardPerSecond = uint256(10 ** 18).div(1 days);
        } else if (_duration == 3) {
            _rewardPerSecond = uint256(15 ** 18).div(1 days);
        } else if (_duration == 4) {
            _rewardPerSecond = uint256(20 ** 18).div(1 days);
        }

        depositorMatrix[account].push(
            Deposit({
                depositTime: block.timestamp,
                depositAmount: _amount,
                expire: block.timestamp.add(_duration * 1 days),
                rewardPerSecond: _rewardPerSecond,
                lastClaimTime: block.timestamp,
                currency: "USDC",
                user: account,
                isWithdrawn: false
            })
        );

        DepositToken.safeTransferFrom(account, address(this), _amount);
    }

    /**
    @dev Allows a user to deposit ETH and earn rewards for a specified duration.
     @param _duration The duration for which the tokens are to be deposited. Must be either 1, 2, 3, or 4 representing 1 day, 2 days, 3 days, or 4 days, respectively.
     */
    function depositETH(uint256 _duration) external payable {
        address account = msg.sender;
        uint256 _amount = msg.value;
        require(
            _duration == 1 ||
                _duration == 2 ||
                _duration == 3 ||
                _duration == 4,
            "Deposit: Deposit duration incorrect"
        );
        require(depositorMatrix[account].length < 5, "Deposit: Maximum number of stakes reached");
        require(_amount >= 1e10, "Error, deposit must be >= 0.0000001 ETH");

        uint256 _rewardPerSecond;
        if (_duration == 1) {
            _rewardPerSecond = uint256(5 ** 18).div(1 days);
        } else if (_duration == 2) {
            _rewardPerSecond = uint256(10 ** 18).div(1 days);
        } else if (_duration == 3) {
            _rewardPerSecond = uint256(15 ** 18).div(1 days);
        } else if (_duration == 4) {
            _rewardPerSecond = uint256(20 ** 18).div(1 days);
        }

        depositorMatrix[account].push(
            Deposit({
                depositTime: block.timestamp,
                depositAmount: _amount,
                expire: block.timestamp.add(_duration * 1 days),
                rewardPerSecond: _rewardPerSecond,
                lastClaimTime: block.timestamp,
                currency: "ETH",
                user: account,
                isWithdrawn: false
            })
        );
    }

    /**
      @dev Withdraws the deposit made in ETH by the specified depositor and the corresponding rewards
      @param account The address of the depositor
      @param index The index of the deposit to withdraw
       Requirements:
        The caller must be a valid depositor.
        The deposit index must be within bounds.
        Only the depositor can withdraw their deposit and rewards.
        The deposit currency must be ETH.
        The deposit duration must have passed.
     */
    function withdrawETH(address account, uint256 index) external {
        require(isDepositor(account), "Withdraw: No Depositor");
        Deposit[] storage deposits = depositorMatrix[account];
        require(index < deposits.length, "Withdraw: Invalid deposit index");

        Deposit storage currentdeposit = deposits[index];
        require(
            currentdeposit.user == account,
            "Withdraw: Only depositor can withdraw"
        );
        require(
            keccak256(bytes(currentdeposit.currency)) == keccak256(bytes("ETH")),
            "Withdraw: Invalid currency"
        );

        if (
            currentdeposit.depositAmount > 0 &&
            !currentdeposit.isWithdrawn
        ) {
            uint256 refundRate = 100;
            uint256 refundAmount = currentdeposit
                .depositAmount
                .mul(refundRate)
                .div(100);

            if (block.timestamp < currentdeposit.expire) {
                revert("Withdraw: Deposit duration not yet passed");
            }

            currentdeposit.isWithdrawn = true;

            (success, ) = payable(account).call{value: refundAmount}("");
            require(success);
        } else {
            revert("Withdraw: Invalid deposit currency");
        }
    }

    /**
    @dev Withdraws the deposit made in USDC by the specified depositor and the corresponding rewards
    @param account The address of the depositor
    @param index The index of the deposit to withdraw
      Requirements:
        The caller must be a valid depositor.
        The deposit index must be within bounds.
        Only the depositor can withdraw their deposit and rewards.
        The deposit currency must be USDC.
        The deposit duration must have passed.
     */
    function withdrawUSDC(address account, uint256 index) external {
        require(isDepositor(account), "Withdraw: No Depositor");
        Deposit[] storage deposits = depositorMatrix[account];
        uint256 depositCount = deposits.length;
        require(depositCount > 0, "Withdraw: No Deposits Found");
        require(index < deposits.length, "Withdraw: Invalid deposit index");
        uint256 totalUSDCRefundAmount = 0;

        Deposit storage userdeposit = deposits[index];
        require(
            userdeposit.user == account,
            "Withdraw: Only depositor can withdraw rewards"
        );
        require(
            keccak256(bytes(userdeposit.currency)) == keccak256(bytes("USDC")),
            "Withdraw: Invalid currency"
        );

        if (userdeposit.depositAmount > 0 && !userdeposit.isWithdrawn) {
            uint256 refundRate = 100;
            uint256 refundAmount = userdeposit
                .depositAmount
                .mul(refundRate)
                .div(100);
            if (block.timestamp >= userdeposit.expire) {
                totalUSDCRefundAmount += refundAmount;
                userdeposit.isWithdrawn = true;
            } else {
                revert("Withdraw: Deposit duration not yet passed");
            }
        }

        require(totalUSDCRefundAmount > 0, "Withdraw: No USDC Deposits Found");

        DepositToken.safeTransfer(account, totalUSDCRefundAmount);
    }

    /**

    @dev Allows a depositor to claim and delete all rewards in ETH for a specific deposit.
    @param depositor The address of the depositor.
    @param index The index of the deposit to claim rewards from.
    Requirements:
    The depositor must be registered as a depositor.
    The index must be valid for the depositor's deposits.
    The deposit currency must be ETH.
    The depositor must be the owner of the deposit.
    The deposit must have been withdrawn.
    The deposit must have been claimed at least once.
    There must be rewards available to claim.
    */
    function claimAndDeleteAllRewardsETH(
        address depositor,
        uint256 index
    ) external {
        require(
            isDepositor(depositor),
            "Claim And Delete All ETH: No Depositor"
        );

        Deposit[] storage deposits = depositorMatrix[depositor];

        uint256 totalReward = 0;

        require(
            index < deposits.length,
            "Claim And Delete All ETH: Invalid index"
        );

        Deposit storage currentuserdeposit = deposits[index];

        require(
            currentuserdeposit.lastClaimTime != 0,
            "Claim And Delete All ETH: Deposit has not been claimed yet"
        );
        require(index < deposits.length, "Withdraw: Invalid deposit index");
        require(
            keccak256(bytes(currentuserdeposit.currency)) ==
                keccak256(bytes("ETH")),
            "Claim And Delete All ETH: Invalid currency"
        );

        require(
            currentuserdeposit.user == depositor,
            "Claim And Delete All ETH: Only depositor can claim rewards"
        );

        require(
            currentuserdeposit.isWithdrawn,
            "Claim And Delete All ETH: ETH not withdrawn"
        );

        uint256 availableReward = calculateRewards(currentuserdeposit);
        totalReward += availableReward;

        require(
            totalReward > 0,
            "Claim And Delete All ETH: No rewards available"
        );

        // Delete the deposit
        delete depositorMatrix[depositor][index];

        FarmCoin.safeTransfer(depositor, totalReward);
    }

    /**
    @dev Allows a depositor to claim and delete a reward in USDC for a specific deposit.
    @param depositor The address of the depositor.
    @param index The index of the deposit to claim rewards from.
    Requirements:
    The depositor must be registered as a depositor.
    The index must be valid for the depositor's deposits.
    The deposit currency must be USDC.
    The depositor must be the owner of the deposit.
    The deposit must have been withdrawn.
    The deposit must have been claimed at least once.
    There must be rewards available to claim.
    */
    function claimAndDeleteRewardUSDC(
        address depositor,
        uint256 index
    ) external {
        require(
            isDepositor(depositor),
            "Claim and Delete Reward USDC: No Depositor"
        );
        Deposit[] storage deposits = depositorMatrix[depositor];
        require(
            index < deposits.length,
            "Claim and Delete Reward USDC: Invalid index"
        );

        Deposit storage rewarddeposit = deposits[index];
        require(
            rewarddeposit.lastClaimTime != 0,
            "Claim And Delete All ETH: Deposit has not been claimed yet"
        );
        require(index < deposits.length, "Withdraw: Invalid deposit index");
        require(
            keccak256(bytes(rewarddeposit.currency)) ==
                keccak256(bytes("USDC")),
            "Claim and Delete Reward USDC: Invalid currency"
        );
        require(
            rewarddeposit.user == depositor,
            "Claim and Delete Reward USDC: Only depositor can claim rewards"
        );
        require(
            rewarddeposit.isWithdrawn,
            "Claim and Delete Reward USDC: USDC not withdrawn"
        );

        uint256 availableReward = calculateRewards(rewarddeposit);

        require(
            availableReward > 0,
            "Claim and Delete Reward USDC: No rewards available"
        );

        // Delete the deposit
        delete depositorMatrix[depositor][index];
        
        FarmCoin.safeTransfer(depositor, availableReward);
    }

    /**
    @dev Returns the available rewards for the deposit at the given index for the caller.
    @param index The index of the deposit for which the rewards are to be calculated.
    @return The available rewards for the deposit at the given index.
    Requirements:
    The caller must be a depositor.
    */
    function getRewardByIndex(uint256 index) external view returns (uint256) {
        address account = msg.sender;

        require(isDepositor(account), "Claim By Index: No Depositor");

        Deposit[] storage deposits = depositorMatrix[account];

        Deposit storage depoistData = getDepositDataByIndex(deposits, index);

        uint256 availableReward = calculateRewards(depoistData);

        return availableReward;
    }

    /**
    @dev Internal function that checks whether an account has made any deposits or not.
    @param account The address to check.
    @return A boolean indicating whether the account has made any deposits or not.
    */
    function isDepositor(address account) internal view returns (bool) {
        return depositorMatrix[address(account)].length > 0;
    }

    /**
    @dev Retrieves the deposit data by index from an array of deposits.
    @param deposits An array of deposits belonging to a depositor.
    @param index The index of the deposit to retrieve.
    @return The deposit data at the specified index.
    @dev Requires that the depositor has made at least one deposit, and that the index is within the range of the array.
    */
    function getDepositDataByIndex(
        Deposit[] storage deposits,
        uint256 index
    ) private view returns (Deposit storage) {
        uint256 numberOfDeposits = deposits.length;

        require(numberOfDeposits > 0, "Get Index: No Depositor");

        require(index < numberOfDeposits, "Get Index: Index overflow");

        return deposits[index];
    }

    /**
    @dev This function returns all the deposit data for the calling depositor.
    @return An array of Deposit struct, each containing depositTime, depositAmount, expire, index, lastClaimTime, currency, user, and isWithdrawn fields.
    The struct array contains all active and past deposits of the depositor.
    If there are no active deposits, an empty Deposit array is returned.
    */
    function getallDepositData() public view returns (Deposit[] memory) {
        address depositor = msg.sender;
        Deposit[] storage deposits = depositorMatrix[depositor];
        uint256 depositCount = deposits.length;

        Deposit[] memory result = new Deposit[](depositCount);
        uint256 resultIndex = 0;

        for (uint256 i = 0; i < depositCount; i++) {
            Deposit storage datadeposit = deposits[i];

            if (datadeposit.depositAmount > 0) {
                result[resultIndex] = Deposit(
                    datadeposit.depositTime,
                    datadeposit.depositAmount,
                    datadeposit.expire,
                    i,
                    datadeposit.lastClaimTime,
                    datadeposit.currency,
                    datadeposit.user,
                    datadeposit.isWithdrawn
                );
                resultIndex++;
            }
        }

        if (resultIndex == 0) {
            // no staking right now
            return new Deposit[](0);
        }

        Deposit[] memory finalResult = new Deposit[](resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            finalResult[i] = result[i];
        }

        return finalResult;
    }

    /**
    @dev Calculates the available reward for a deposit by taking the difference between the current block timestamp and the last time the reward was claimed,
    then multiplying it by the reward per second.
    @param _depoistData The deposit data for which to calculate the available reward.
    @return The available reward for the deposit.
    */
    function calculateRewards(
        Deposit storage _depoistData
    ) internal view returns (uint256) {
        uint256 passedTime = block.timestamp.sub(_depoistData.lastClaimTime);
        return _depoistData.rewardPerSecond.mul(passedTime);
    }
}
