// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "../lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

contract Rebase_Token is ERC20, Ownable, AccessControl {
    ///////////////////////////////////////////////// Constructor /////////////////////////////////////////////////
    constructor() ERC20("Rebase_Token", "RBT")  {
        //_mint(msg.sender, 1000000 * 10e18);
    }

    ///////////////////////////////////////////////// Errors /////////////////////////////////////////////////
    error InvalidInterestRate(uint);

    ///////////////////////////////////////////////// State Variables /////////////////////////////////////////////////
    uint256 public Precesion_factor = 1e27;
    uint256 private s_interestrate = (5*Precesion_factor)/1e8;    // 5%
    bytes32 constant internal s_mintandburnrole = keccak256("MINT_AND_BURN_ROLE");
    
    

    ///////////////////////////////////////////////// Mappings /////////////////////////////////////////////////
    mapping(address user => uint256 interest) private s_userInterest;
    mapping(address user => uint256 lastupdate) private s_userLastUpdate;
    ///////////////////////////////////////////////// Events /////////////////////////////////////////////////
    event InterestRateUpdated(uint oldInterestRate, uint newInterestRate);

    ///////////////////////////////////////////////// Functions /////////////////////////////////////////////////
/*
@dev: if new interest rate is greater than current interest rate, revert
@dev: if new interest rate is less than current interest rate, update interest rate
@dev: emit event when interest rate is updated
@param: _newinterestrate = new interest rate
*/

    function setinterestrate(uint _newinterestrate) external onlyOwner() {
    if(_newinterestrate > s_interestrate){
        revert InvalidInterestRate(_newinterestrate);
    } 
    s_interestrate = _newinterestrate;
    emit InterestRateUpdated(s_interestrate, _newinterestrate);
    }

/*
@dev: mint accrued interest to user (interest that the user has earned because after that the interst for user will be updated)
@dev: update user interest rate
@dev: mint token to user 
@param: _to = address of the user
@param: _amount = amount of token to mint 
*/

    function mint(address _to, uint _amount,uint _interestrate) external onlyRole(s_mintandburnrole) {
    _mintaccruedinterest(_to);
    s_userInterest[_to] = _interestrate;
    _mint(_to, _amount);
    }

/*
@dev: calculate accrued interest since last update (_calculateaccruedinterestsincelastupdate)
@param: account = address of the user
@dev: return principle amount + accrued interest
*/

    function balanceOf(address account) public view override returns (uint256) {
        
        return (super.balanceOf(account) * _calculateaccruedinterestsincelastupdate(account)) / Precesion_factor;
    }

/*
@dev: calculate accrued interest since last update
@param: _user = address of the user
@method: 1. Calculate no. of seconds since last update
         2. Calculate accruded interest that'll be (interest for user * time since last update)         
*/
    function _calculateaccruedinterestsincelastupdate(address _user) internal view returns (uint256 lineraInterest) {
      uint256 lastupdate = block.timestamp - s_userLastUpdate[_user];
      return lineraInterest = Precesion_factor + (s_userInterest[_user] * lastupdate);
    }


/*
(1) Calculcate user's principle amount of rebase token
(2) Calculate user's accrued interest +  current balance of rebase token
(2)-(1) = no. of tokens we need to mint
*/

    function _mintaccruedinterest(address _user) internal {
      uint currentbalance = super.balanceOf(_user);
      uint currenttotalbalance = balanceOf(_user);
      uint accruedinterest = currenttotalbalance - currentbalance;
      s_userLastUpdate[_user] = block.timestamp;
      _mint(_user, accruedinterest);
    }

/*
@dev: get interest rate of the user
@param: _user = address of the user
@dev: return interest rate of the user
*/
    function _getInterestRate(address _user) internal view returns (uint256) {
      return s_userInterest[_user];
    }

    // burn function

    function burn(address _user, uint _amount) external onlyRole(s_mintandburnrole){
      _mintaccruedinterest(_user);
      _burn(_user, _amount);
    }

/*
@dev: transfer function one user can transfer to another user
@dev: mint accrued interest to user
@dev: mint accrued interest to receiver
@dev: if amount is greater than type(uint256).max, set amount to balance of user
@dev: if receiver's interest rate is 0, set it to sender's interest rate
@param: _to = address of the receiver
@param: _amount = amount of token to transfer
@return yes if exceuted successfully 
*/

    function transfer(address _to, uint256 _amount) public override returns (bool) {
      _mintaccruedinterest(msg.sender);
      _mintaccruedinterest(_to);

      if(_amount > type(uint256).max) {
        _amount = balanceOf(msg.sender);
      }
      if(s_userInterest[_to] == 0) {
        s_userInterest[_to] = s_userInterest[msg.sender];
      }
      return super.transfer(_to, _amount);
    }

/*
@dev: transferFrom function one user can transfer to another user but after approval
@dev: mint accrued interest to user
@dev: mint accrued interest to receiver
@dev: if amount is greater than type(uint256).max, set amount to balance of user
@dev: if receiver's interest rate is 0, set it to sender's interest rate
@param: _from = address of the user
@param: _to = address of the receiver
@param: _amount = amount of token to transfer
@return yes if exceuted successfully 
*/
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
      _mintaccruedinterest(_from);
      _mintaccruedinterest(_to);

      if(_amount > type(uint256).max) {
        _amount = balanceOf(_from);
      }
      if(s_userInterest[_to] == 0) {
        s_userInterest[_to] = s_userInterest[_from];
      }
      return super.transferFrom(_from, _to, _amount);
    }

/*
@dev: grant mint and burn role to an address
@param: _user = address of the user
*/
    function grantMintandBurnRole(address _user) external onlyOwner() {
      _grantRole(s_mintandburnrole, _user);
    }

/*
@dev: get principle balance of the user without any accrued interest
@param: _user = address of the user
@dev: return principle balance of the user
*/

    function principlabalance(address _user) public view returns (uint256) {
      return super.balanceOf(_user);
    }

/*
@dev: get current interest rate
@dev: return current interest rate
*/
    function getCurrentInterestRate() public view returns (uint256) {
      return s_interestrate;
    }
}