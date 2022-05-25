// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Coin is ERC20, Ownable {
    using SafeMath for uint256;
    uint256 MaxSupply = 1000000 ether; // max token supply  1 000 000
    mapping(address => bool) public controllers; // list of the contract controllers

    constructor() ERC20("My Coin", "MC") {
        transferOwnership(msg.sender);
        _mint(msg.sender, 500000 ether); //send 500 000 tokens to contract deployer
        _mint(address(this), 500000 ether); //send 500 000 tokens to contract
    }

    /**
     * @dev modifier checks if the address is in the controller list
     */
    modifier onlyController() {
        require(controllers[msg.sender], "COIN: JUST_CONTROLLERS_CAN_CALL");
        _;
    }

    /**
     * @dev add a new address to the controller list
     * @param _controller: address of the contract address to be added to the controller list
     */
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    /**
     * @dev remove a address from the controller list
     * @param _controller: address of the contract address to be removed from the controller list
     */
    function removeController(address _controller) external onlyOwner {
        controllers[_controller] = false;
    }

    /**
     * @dev burn tokens function just callable by the owner
     * @param _amount: amount of tokens to burn
     */
    function Burn(uint256 _amount) external onlyOwner {
        require(balanceOf(msg.sender) >= _amount, "COIN: BALANCE_TO_LOW");
        _burn(msg.sender, _amount);
    }

    /**
     * @dev reward function to pay rewards to users just callable by the controllers
     * @param _to: address of the receiver
     * @param _amount: amount of tokens for send
     */
    function payRewards(address _to, uint256 _amount) external onlyController {
        uint256 contractBalance = balanceOf(address(this));
        require(_amount <= contractBalance, "COIN: CONTRACT_BALANCE_TO_LOW");
        ERC20(this).transfer(_to, _amount);
    }

    /**
     * @dev transfer coins from the contract to the owner just callable by the owner
     * @param _amount: amount of tokens for send
     */
    function transferCoin(uint256 _amount) external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(_amount <= contractBalance, "COIN: CONTRACT_BALANCE_TO_LOW");
        ERC20(this).transfer(msg.sender, _amount);
    }
}
