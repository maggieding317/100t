// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

import "./libs/IUniswap.sol";

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return _div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function _div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract t100 is ERC20, Pausable, Ownable, ERC20Permit {
    // contract LiquidityPool is Context, IERC20, Ownable {
    using SafeMath for uint256;
    // using Address for address;

    uint constant DAY_IN_SECONDS = 86400;
    // uint constant DAY_IN_SECONDS = 180;

    uint256 public _totalSupply = 1000000000 * 10 ** 7 * 10 ** 9;
    uint256 public _initialRelease = _totalSupply.mul(4).div(10);
    uint256 public _forTESTING = _initialRelease.div(2);
    uint256 public _totalRewards = _totalSupply.mul(6).div(10);
    // uint256 public totalAddedLiquidity;
    uint32 public constant tax_burn = 2;
    uint32 public constant tax_liquidity = 3;
    uint32 public constant tax_marketing = 2;
    uint32 public constant tax_team = 3;
    uint256 public constant rewardClaimingDay = 7;

    address public rewardClaimingAccount =
        0xCD099Fb81ccf43579ccC9fDc4436F530af28FF5e;
    address[] public stakersArray; // array of all stakers address
    uint256 public totalLiquidity;
    uint256[] public totalLiquidityEachDay;
    uint256 public daynow;
    uint256 public immutable dayBefore;
    struct snapshot {
        uint256[] date;
        uint256[] liquidity; //last check date
    }
    struct rewardCalculation {
        uint256 startDate;
        uint256 originalReward;
        uint256 today;
        uint256[] dates;
        uint256[] liquidity;
        uint256 dateLength;
        uint256 nextDate;
        uint256 currentLiquidity;
        uint256 totalLiquidityOfTheDay;
        uint256 totalOfTheDay;
        uint256 dayDifference;
        uint256 reward;
    }
    uint256 public constant timeUnit = 1;
    uint256 public constant rewardRatioNumerator = 9;
    uint256 public constant rewardRatioDenominator = 10;
    uint256 public constant fixedRewardRatioNumerator = 5;
    uint256 public constant fixedRewardRatioDenominator = 100;

    mapping(address => uint256) public addedLiquidity;
    mapping(address => uint256) public lastRewardDate; // last time claiming reward date for each address
    uint256[] public rewardDaily; //every day total reward given, index is day
    uint256 public rewardDailyFixed = 100000;

    mapping(address => uint256) private _tOwned;
    mapping(address => snapshot) private recordSnapshot;

    uint256 private constant MAX = ~uint256(0);

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 private numTokensSellToAddToLiquidity = _totalSupply.mul(6).div(10);

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event AddLiquidity(uint token, uint eth, uint time);
    event _staked(address from, uint amount, uint time);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("t100", "t100") ERC20Permit("t100") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        daynow = 0;
        totalLiquidity = 0;

        dayBefore = block.timestamp.div(DAY_IN_SECONDS);
        _mint(owner(), _forTESTING); // should be put into liquidity pool.
        _mint(address(this), _forTESTING);
        _mint(rewardClaimingAccount, _totalRewards);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function t100Balance(
        address tokenContractAddress
    ) public view returns (uint) {
        IERC20 token = IERC20(tokenContractAddress); // token is cast as type IERC20, so it's a contract
        return token.balanceOf(address(this));
    }

    function t100Approve(
        address tokenContractAddress,
        address spender,
        uint256 amount
    ) public {
        IERC20 token = IERC20(tokenContractAddress); // token is cast as type IERC20, so it's a contract
        token.approve(spender, amount);
    }

    function totalSupply(uint256 amount) external onlyOwner {
        _totalSupply = amount;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _tOwned[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _tOwned[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _tOwned[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (inSwapAndLiquify) {
            _transferWithoutFee(_msgSender(), recipient, amount);
            return true;
        }
        _transferWithLP(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (inSwapAndLiquify) {
            _transferWithoutFee(sender, recipient, amount);
            return true;
        }
        _spendAllowance(sender, _msgSender(), amount);
        require(amount < allowance(sender, _msgSender()), "Exceed allowance");
        _transferWithLP(sender, recipient, amount);
        approve(
            sender,
            _msgSender(),
            allowance(sender, _msgSender()).sub(amount)
        );
        return true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    fallback() external payable {}

    function _getTValues(
        uint256 tAmount
    ) private pure returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 amountBurn = (tAmount * tax_burn) / 100;
        uint256 amountLiquidity = (tAmount * tax_liquidity) / 100;
        uint256 amountMarketing = (tAmount * tax_marketing) / 100;
        uint256 amountTeam = (tAmount * tax_team) / 100;

        uint256 tTransferAmount = tAmount -
            amountBurn -
            amountLiquidity -
            amountMarketing -
            amountTeam;
        return (
            tTransferAmount,
            amountBurn,
            amountLiquidity,
            amountMarketing,
            amountTeam
        );
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _approve(owner, spender, amount);
        emit Approval(owner, spender, amount);
    }

    function _transferWithLP(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquifyForTax(contractTokenBalance);
        }
        _tokenTransfer(from, to, amount);
    }

    function swapAndLiquifyForTax(
        uint256 contractTokenBalance
    ) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEthForTax(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidityForTax(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEthForTax(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityForTax(
        uint256 tokenAmount,
        uint256 ethAmount
    ) private lockTheSwap {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner() /*0x0000000000000000000000000000000000000001,*/,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 amountBurn,
            uint256 amountLiquidity,
            uint256 amountMarketing,
            uint256 amountTeam
        ) = _getTValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _takeLiquidity(amountLiquidity);
        _reflectFee(amountBurn, amountMarketing, amountTeam);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferWithoutFee(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);

        emit Transfer(sender, recipient, tAmount);
    }

    function _reflectFee(
        uint256 amountBurn,
        uint256 amountMarketing,
        uint256 amountTeam
    ) private {
        _tOwned[owner()] = _tOwned[owner()].add(amountMarketing); //address change to specific address.
        _tOwned[owner()] = _tOwned[owner()].add(amountTeam); //address change to specific address.
        _totalSupply = _totalSupply.sub(amountBurn);
    }

    function swapYieldFarming(uint amount) public {
        uint256 liquidityBefore = t100Balance(uniswapV2Pair);
        swapAndLiquify(msg.sender, amount);
        uint256 liquidityAfter = t100Balance(uniswapV2Pair);
        uint256 newLiquidity = liquidityAfter - liquidityBefore;
        _recordYieldFarming(newLiquidity, msg.sender);
    }

    function swapAndLiquify(
        address account,
        uint amount
    ) internal lockTheSwap returns (uint) {
        uint half = amount / 2;
        uint half2 = amount - half;
        uint initB = address(this).balance;

        _approve(account, address(this), amount);
        transferFrom(account, address(this), amount);

        //swap function, use half
        swapForETH(half);
        uint currentB = address(this).balance;
        uint wethamount = currentB - initB;

        //add liquity function use wethamount + half2
        addLiquidity(account, half2, wethamount);
        //call event
        emit AddLiquidity(half2, wethamount, block.timestamp);
        return half2;
    }

    function swapForETH(uint amount) internal lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), amount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(
        address account,
        uint tokenAmount,
        uint wethAmount
    ) internal lockTheSwap {
        uint initB = address(this).balance - wethAmount;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: wethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this) /*0x0000000000000000000000000000000000000001,*/,
            block.timestamp
        );
        //calculate eth difference to see how much eth being sent back
        uint currentB = address(this).balance;
        uint balanceDifference = currentB - initB;
        //send eth back to account
        if (balanceDifference != 0) {
            address payable receiver = payable(account);
            receiver.transfer(balanceDifference);
        }
    }

    function addLiquidityForYieldFarming(
        uint tokenAmount
    ) public payable lockTheSwap {
        uint256 liquidityBefore = t100Balance(uniswapV2Pair);
        uint initB = address(this).balance - msg.value;
        uint initToken = balanceOf(address(this));

        _approve(msg.sender, address(this), tokenAmount);
        transferFrom(msg.sender, address(this), tokenAmount);
        //contract to pool
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this) /*0x0000000000000000000000000000000000000001,*/,
            block.timestamp
        );

        //calculate eth difference to see how much eth being sent back 10432751
        uint currentB = address(this).balance;
        uint balanceDifference = currentB - initB;
        //send eth back to account
        if (balanceDifference != 0) {
            address payable receiver = payable(msg.sender);
            receiver.transfer(balanceDifference);
        }

        uint currentToken = balanceOf(address(this));
        uint tokenDifference = currentToken - initToken;
        //send token back to account
        if (tokenDifference != 0) {
            _tOwned[address(this)] = _tOwned[address(this)].sub(
                tokenDifference
            );
            _tOwned[msg.sender] = _tOwned[msg.sender].add(tokenDifference);
        }

        uint256 liquidityAfter = t100Balance(uniswapV2Pair);
        uint256 liquidityDifference = liquidityAfter - liquidityBefore;
        _recordYieldFarming(liquidityDifference, msg.sender);
    }

    function _initAddLiquidity(uint tokenAmount) public payable lockTheSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        // _approve(account, address(uniswapV2Router), tokenAmount);
        _approve(address(this), uniswapV2Pair, tokenAmount);
        // _approve(account, uniswapV2Pair, tokenAmount);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this) /*0x0000000000000000000000000000000000000001,*/,
            block.timestamp
        );
    }

    function removeLiquidity(
        address account,
        uint liquidity
    ) public lockTheSwap {
        uint256 currentLP = t100Balance(uniswapV2Pair);
        t100Approve(uniswapV2Pair, address(uniswapV2Router), currentLP);
        uniswapV2Router.removeLiquidityETH(
            address(this),
            liquidity,
            0,
            0,
            account,
            block.timestamp
        );
    }

    // !!!!For TESTING
    function stakersData(
        address account
    )
        external
        view
        returns (uint256[] memory dates, uint256[] memory liquidity)
    {
        dates = recordSnapshot[account].date;
        liquidity = recordSnapshot[account].liquidity;
    }

    //yieldFarming.sol
    //should first initiallize
    function _recordYieldFarming(uint amount, address account) internal {
        if (
            addedLiquidity[account] == 0 &&
            recordSnapshot[account].date.length == 0
        ) {
            stakersArray.push(account);
            recordSnapshot[account].date.push(0);
            recordSnapshot[account].liquidity.push(0);
        }
        addedLiquidity[account] += amount;
        uint256 currentLiquidity = addedLiquidity[account];

        _updateYieldFarming(account, currentLiquidity);
        totalLiquidity += amount;
        emit _staked(account, amount, block.timestamp);
    }

    function recordTotalLiquidity() public returns (bool) {
        uint256 today = getDay();
        if (totalLiquidityEachDay.length < today) {
            for (uint i = totalLiquidityEachDay.length; i < today; i++) {
                totalLiquidityEachDay.push(totalLiquidity);
            }
        }
        totalLiquidityEachDay.push(totalLiquidity);
        if (totalLiquidityEachDay.length <= today) {
            return false;
        }
        return true;
    }

    function getTotalLiquidity() public view returns (uint256[] memory) {
        return totalLiquidityEachDay;
    }

    //replace account with msg.sender for safety
    function _withdraw(address account, uint amount) public {
        require(amount <= addedLiquidity[account]);
        removeLiquidity(account, amount);
        addedLiquidity[account] -= amount;
        daynow = getDay();
        uint256 currentLiquidity = addedLiquidity[account];

        _updateYieldFarming(account, currentLiquidity);
        totalLiquidity = totalLiquidity.sub(amount);

        if (addedLiquidity[account] == 0) {
            address[] memory _stakersArray = stakersArray;
            for (uint256 i = 0; i < _stakersArray.length; ++i) {
                if (_stakersArray[i] == account) {
                    stakersArray[i] = _stakersArray[_stakersArray.length - 1];
                    stakersArray.pop();
                    break;
                }
            }
        }
        emit _staked(account, currentLiquidity, block.timestamp);
    }

    function _updateYieldFarming(
        address account,
        uint256 currentLiquidity
    ) internal {
        daynow = getDay();
        uint256 dateLength = recordSnapshot[account].date.length;
        uint256 prev = recordSnapshot[account].date[dateLength - 1]; // last element

        if (daynow != prev) {
            recordSnapshot[account].date.push(daynow);
            recordSnapshot[account].liquidity.push(currentLiquidity);
        } else {
            recordSnapshot[account].liquidity[
                dateLength - 1
            ] = currentLiquidity;
        }
    }

    function _claimReward() public {
        uint256 reward;
        uint256 burntReward;

        (reward, burntReward) = _calcReward(msg.sender);
        //create an account to mint for rewards *****
        bool success = rewardTransfer(
            rewardClaimingAccount,
            msg.sender,
            reward
        );
        require(success);
        _burn(rewardClaimingAccount, burntReward);
        //if successful
        lastRewardDate[msg.sender] = getDay();
    }

    function rewardTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _transferWithLP(from, to, amount);
        return true;
    }

    function getStakeInfo(
        address account
    )
        public
        view
        returns (uint256 tokensStaked, uint256 rewards, uint256 burn)
    {
        tokensStaked = addedLiquidity[account];
        (rewards, burn) = _calcReward(account);
    }

    function pow(uint n, uint e) public pure returns (uint) {
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return n;
        } else {
            uint p = pow(n, e.div(2));
            p = p.mul(p);
            if (e.mod(2) == 1) {
                p = p.mul(n);
            }
            return p;
        }
    }

    function _calcReward(
        address account
    ) internal view virtual returns (uint256 totalReward, uint256 totalBurn) {
        rewardCalculation memory calc;
        calc.startDate = lastRewardDate[account];
        // uint256 startDate
        // uint256 originalReward;
        calc.today = getDay();
        if (recordSnapshot[account].date.length == 0) {
            return (0, 0);
        }
        calc.dates = recordSnapshot[account].date;
        calc.liquidity = recordSnapshot[account].liquidity;
        uint256 j = 1;

        calc.dateLength = calc.dates.length; // 1
        // uint256 currentDate = dates[j];

        calc.nextDate = calc.today; // 0
        calc.currentLiquidity = 0;

        if (calc.dateLength != 1) {
            while (calc.dates[j] <= calc.startDate && j < calc.dateLength - 1) {
                j++;
            }
            calc.nextDate = calc.dates[j];
            calc.currentLiquidity = calc.liquidity[j - 1];
        } else {
            calc.currentLiquidity = calc.liquidity[0];
        }
        calc.reward = 0;
        calc.dayDifference;
        for (uint i = calc.startDate; i < calc.today; i++) {
            if (i == calc.nextDate) {
                j++;
                if (j < calc.dateLength - 1) {
                    calc.nextDate = calc.dates[j];
                } else {
                    calc.nextDate = calc.today;
                }
            }
            calc.currentLiquidity = calc.liquidity[j - 1];
            calc.totalLiquidityOfTheDay = totalLiquidityEachDay[i];
            if (calc.totalLiquidityOfTheDay == 0) {
                continue;
            }
            calc.totalOfTheDay = getRewardForEachMonth(i);

            calc.dayDifference = calc.today.sub(i); // need to get absolute value or else overflow.
            if (calc.dayDifference < rewardClaimingDay) {
                calc.dayDifference = rewardClaimingDay.sub(calc.dayDifference);
            } else {
                calc.dayDifference = calc.dayDifference.sub(rewardClaimingDay);
            }
            if (calc.dayDifference > 30) {
                calc.dayDifference = 30;
            }
            // oReward = currentLiquidity.div(totalLiquidity).mul(totalOfTheDay);
            calc.reward = calc
                .currentLiquidity
                .div(calc.totalLiquidityOfTheDay)
                .mul(calc.totalOfTheDay)
                .mul(pow(rewardRatioNumerator, calc.dayDifference))
                .div(pow(rewardRatioDenominator, calc.dayDifference));
            // stakers[account][i].rewardForTheDay = reward;
            // uint256 oReward = amountRatio.mul(totalOfTheDay);
            calc.originalReward += calc
                .currentLiquidity
                .div(calc.totalLiquidityOfTheDay)
                .mul(calc.totalOfTheDay);
            totalReward += calc.reward;
            // stakers[account][i].endDate = daynow;
        }
        totalBurn = calc.originalReward - totalReward;
    }

    function mintRewardEachMonth() public returns (bool) {
        uint256 mintAmount = getRewardForEachMonth(getDay());
        _mint(rewardClaimingAccount, mintAmount);
        return true;
    }

    function getDay() public view returns (uint256) {
        uint256 dayNumber = block.timestamp.div(DAY_IN_SECONDS);
        return dayNumber.sub(dayBefore);
    }

    function getRewardForEachMonth(
        uint256 date
    ) public pure returns (uint256 rewardAmount) {
        uint256 month = date.div(30);
        if (month == 1) {
            rewardAmount = 115942028986;
        } else if (1 < month || month <= 3) {
            rewardAmount = 57971014493;
        } else if (4 <= month || month < 7) {
            rewardAmount = 28985507246;
        } else if (7 <= month) {
            rewardAmount = 14492753623;
        }
    }
    // function getMonth(uint256 date) public view returns (uint256) {
    //     uint256 month = date.div(30);
    //     return month;
    // }
}
