pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {

  IERC20 token;
  uint256 public totalLiquidity;
  mapping (address => uint256) public liquidity;
  constructor(address token_addr) {
    token = IERC20(token_addr);
  }

  // write your functions here...
  function init(uint256 tokens) public payable returns (uint256) {
      require(totalLiquidity==0,"DEX:init - already has liquidity");
      totalLiquidity = address(this).balance;
      liquidity[msg.sender] = totalLiquidity;
      require(token.transferFrom(msg.sender, address(this), tokens));
      return totalLiquidity;
}

// XY = K
// At the core of Uniswap is one math function:

// x * y = k

// Assume we have a trading pair for ETH / LW3 Token

// x = reserve balance of ETH in the trading pool

// y = reserve balance of LW3 Token in the trading pool

// k = a constant
// The formula states that k is a constant no matter what the reserves (x and y) are. Every swap made increases the reserve of either ETH or LW3 Token and decreases the reserve of the other.

// Let's try to write that as a formula:

// (x + Δx) * (y - Δy) = k

// where Δx is the amount being provided by the user for sale, and Δy is the amount the user is receiving from the DEX in exchange for Δx.

// Since k is a constant, we can compare the above two formulas to get:

// x * y = (x + Δx) * (y - Δy)

// Now, before a swap occurs, we know the values of x, y, and Δx (given by user). We are interested in calculating Δy - which is the amount of ETH or LW3 Token the user will receive.

// We can simplify the above equation to solve for Δy, and we get the following formula:


// Δy = (y * Δx) / (x + Δx)

function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public pure returns (uint256) {
  uint256 input_amount_with_fee = input_amount * 997;
  uint256 numerator = input_amount_with_fee * output_reserve;
  uint256 denominator = (input_reserve *1000) + input_amount_with_fee;
  return numerator / denominator;
}
function ethToToken() public payable returns (uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 tokens_bought = price(msg.value, address(this).balance - msg.value, token_reserve);
  require(token.transfer(msg.sender, tokens_bought));
  return tokens_bought;
}

function tokenToEth(uint256 tokens) public returns (uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 eth_bought = price(tokens, token_reserve, address(this).balance);
  (bool sent, ) = msg.sender.call{value: eth_bought}("");
  require(sent, "Failed to send user eth.");
  require(token.transferFrom(msg.sender, address(this), tokens));
  return eth_bought;
}

function deposit() public payable returns (uint256) {
  uint256 eth_reserve = address(this).balance - msg.value;
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 token_amount = ((msg.value * token_reserve) / eth_reserve) + 1;
  uint256 liquidity_minted = (msg.value * totalLiquidity) / eth_reserve;
  liquidity[msg.sender] += liquidity_minted;
  totalLiquidity += liquidity_minted;
  require(token.transferFrom(msg.sender, address(this), token_amount));
  return liquidity_minted;
}

function withdraw(uint256 liq_amount) public returns (uint256, uint256) {
uint256 token_reserve = token.balanceOf(address(this));
uint256 eth_amount = (liq_amount * address(this).balance) / totalLiquidity;
uint256 token_amount = (liq_amount * token_reserve) / totalLiquidity;
liquidity[msg.sender] -= liq_amount;
totalLiquidity -= liq_amount;
(bool sent, ) = msg.sender.call{value: eth_amount}("");
require(sent, "Failed to send user eth.");
require(token.transfer(msg.sender, token_amount));
return (eth_amount, token_amount);
}


}