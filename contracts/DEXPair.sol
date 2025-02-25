// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DEXPair {
    // Immutable token addresses
    address public immutable token0;
    address public immutable token1;

    // Reserves of each token
    uint256 public reserve0;
    uint256 public reserve1;

    // ERC20 state variables for LP tokens
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public constant name = "DEXPair LP Token";
    string public constant symbol = "DPLP";
    uint8 public constant decimals = 18;

    // Minimum liquidity to prevent issues with small pools
    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    // Events for tracking activities
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    // Constructor to initialize token pair
    constructor(address _token0, address _token1) {
        require(_token0 != address(0) && _token1 != address(0), "Invalid token address");
        require(_token0 < _token1, "Token order invalid"); // Ensures unique pair
        token0 = _token0;
        token1 = _token1;
    }

    // Internal functions for ERC20 LP token management
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        require(from != address(0), "Burn from zero address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Transfer to zero address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(from != address(0) && to != address(0), "Invalid address");
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Helper function to calculate square root (Babylonian method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return z;
    }

    // Get current reserves
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    // Calculate output amount for a swap (with 0.3% fee)
    function getAmountOut(uint256 amountIn, address tokenIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "Insufficient input amount");
        require(tokenIn == token0 || tokenIn == token1, "Invalid token");
        (uint256 reserveIn, uint256 reserveOut) = tokenIn == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 amountInWithFee = amountIn * 997; // 0.3% fee (997/1000)
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // Add liquidity to the pool
    function addLiquidity(uint256 amount0, uint256 amount1) external returns (uint256 liquidity) {
        require(amount0 > 0 && amount1 > 0, "Insufficient amounts");

        // Transfer tokens to the contract first
        require(IERC20(token0).transferFrom(msg.sender, address(this), amount0), "Token0 transfer failed");
        require(IERC20(token1).transferFrom(msg.sender, address(this), amount1), "Token1 transfer failed");

        if (totalSupply == 0) {
            // Initial liquidity: mint LP tokens based on sqrt(amount0 * amount1)
            liquidity = sqrt(amount0 * amount1);
            require(liquidity > MINIMUM_LIQUIDITY, "Below minimum liquidity");
            _mint(address(0), MINIMUM_LIQUIDITY); // Lock minimum liquidity permanently
            _mint(msg.sender, liquidity - MINIMUM_LIQUIDITY);
        } else {
            // Subsequent liquidity: mint proportional to existing reserves
            (uint256 _reserve0, uint256 _reserve1) = getReserves();
            uint256 liquidity0 = (amount0 * totalSupply) / _reserve0;
            uint256 liquidity1 = (amount1 * totalSupply) / _reserve1;
            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
            require(liquidity > 0, "Insufficient liquidity minted");
            _mint(msg.sender, liquidity);
        }

        // Update reserves
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
        emit Mint(msg.sender, amount0, amount1);
    }

    // Remove liquidity from the pool
    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        require(liquidity > 0, "Insufficient liquidity");
        require(balanceOf[msg.sender] >= liquidity, "Insufficient LP tokens");

        // Calculate amounts to return
        (uint256 _reserve0, uint256 _reserve1) = getReserves();
        amount0 = (liquidity * _reserve0) / totalSupply;
        amount1 = (liquidity * _reserve1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "Insufficient amounts");

        // Burn LP tokens before transferring
        _burn(msg.sender, liquidity);

        // Transfer tokens back to user
        require(IERC20(token0).transfer(msg.sender, amount0), "Token0 transfer failed");
        require(IERC20(token1).transfer(msg.sender, amount1), "Token1 transfer failed");

        // Update reserves
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));
        emit Burn(msg.sender, amount0, amount1, msg.sender);
    }

    // Swap tokens with slippage protection
    function swap(uint256 amountIn, address tokenIn, uint256 amountOutMin, address to) external {
        require(amountIn > 0, "Insufficient input amount");
        require(tokenIn == token0 || tokenIn == token1, "Invalid input token");
        require(to != address(0), "Invalid recipient");

        // Calculate output amount
        uint256 amountOut = getAmountOut(amountIn, tokenIn);
        require(amountOut >= amountOutMin, "Insufficient output amount");
        address tokenOut = tokenIn == token0 ? token1 : token0;

        // Transfer input tokens to contract
        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn), "Input transfer failed");

        // Transfer output tokens to recipient
        require(IERC20(tokenOut).transfer(to, amountOut), "Output transfer failed");

        // Update reserves
        reserve0 = IERC20(token0).balanceOf(address(this));
        reserve1 = IERC20(token1).balanceOf(address(this));

        // Emit swap event
        uint256 amount0In = tokenIn == token0 ? amountIn : 0;
        uint256 amount1In = tokenIn == token1 ? amountIn : 0;
        uint256 amount0Out = tokenIn == token0 ? 0 : amountOut;
        uint256 amount1Out = tokenIn == token1 ? 0 : amountOut;
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }
}