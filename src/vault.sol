// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IRebase_Token} from "./interfaces/IRebase_Token.sol";

contract vault {
    ///////////////////////////////////////////////// State Variables /////////////////////////////////////////////////

    IRebase_Token private immutable s_rebase_token;
    
    ///////////////////////////////////////////////// Constructor /////////////////////////////////////////////////
    
    constructor(IRebase_Token _rebase_token) {
        s_rebase_token = _rebase_token;
    }

    ///////////////////////////////////////////////// Errors /////////////////////////////////////////////////
    error TransferFailed();
   
    ///////////////////////////////////////////////// Events /////////////////////////////////////////////////
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    
    ///////////////////////////////////////////////// Functions /////////////////////////////////////////////////

    receive() external payable {
        uint256 interestRate = s_rebase_token._getInterestRate();
        s_rebase_token.mint(msg.sender, msg.value, interestRate);
    }

/*
@dev: deposit function
@param: _amount = amount of rebase token to deposit
@dev: mint rebase token to user
@dev: emit event when deposit is successful
*/
    
    function deposit() external payable {
        uint256 interestRate = s_rebase_token._getInterestRate();
        s_rebase_token.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

/*
@dev: withdraw function
@param: _amount = amount of rebase token to withdraw
@dev: burn rebase token from user
@dev: transfer eth to user
@dev: emit event when withdraw is successful
*/

    function withdraw(uint _amount) external {
        if(_amount == type(uint256).max) {
        _amount = s_rebase_token.balanceOf(msg.sender);
        }
        s_rebase_token.burn(msg.sender, _amount);
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if(!success) {
            revert TransferFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

/*
@dev: get rebase token address
@dev: return rebase token address
*/

    function getRebaseAddress() external view returns (address) {
        return address(s_rebase_token);
    }
}