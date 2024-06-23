//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interface/IERC20.sol";

contract CPAMM {
    /**
     * variabless needed
     * totalSupply
     * balanceOf
     *
     * //Function Needed
     * mint
     * burn
     * swap
     * addLiquidity
     * removeLiquidity
     * updateReserve
     */
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    //CONSTRUCTOR
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    //FUNCTIONS

    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint256 _res0, uint256 _res1) private {
        reserve0 = _res0;
        reserve1 = _res1;
    }

    function swap(
        address _tokenIn,
        uint256 _amount
    ) external returns (uint256 amountOut) {
        require(
            _tokenIn == address(token0) || _tokenIn == address(token1),
            "Invalid Token"
        );
        bool isToken0 = _tokenIn == address(token0);

        (
            IERC20 tokenIn,
            IERC20 tokenOut,
            uint256 resIn,
            uint256 resOut
        ) = isToken0
                ? (token0, token1, reserve0, reserve1)
                : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amount);
        uint256 amountIn = tokenIn.balanceOf(address(this)) - resIn;

        amountOut = (amountIn * 997) / 1000;

        (uint256 res0, uint256 res1) = isToken0
            ? (resIn + amountIn, resOut - amountOut)
            : (resOut - amountOut, resIn + amountIn);

        _update(res0, res1);
        tokenOut.transfer(msg.sender, amountOut);
    }

    function addLiquidity(
        uint256 _amount0,
        uint256 _amount1
    ) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        uint256 d0 = bal0 - reserve0;
        uint256 d1 = bal1 - reserve1;

        if (totalSupply > 0) {
            shares = ((d0 + d1) * totalSupply) / (reserve0 + reserve1);
        } else {
            shares = d0 + d1;
        }
        require(shares > 0, "Shares is 0 bro");
        _mint(msg.sender, shares);
        _update(bal0, bal1);
    }

    function removeLiquidity(
        uint256 _shares
    ) external returns (uint256 d0, uint256 d1) {
        d0 = (reserve0 * _shares) / totalSupply;
        d1 = (reserve1 * _shares) / totalSupply;

        _burn(msg.sender, _shares);
        _update(reserve0 - d0, reserve1 - d1);

        if (d0 > 0) {
            token0.transfer(msg.sender, d0);
        }
        if (d1 > 0) {
            token1.transfer(msg.sender, d1);
        }
    }
}
