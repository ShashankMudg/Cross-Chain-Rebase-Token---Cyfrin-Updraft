// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRebase_Token {
    function mint(address _to, uint _amount, uint _interestRate) external;
    function burn(address _user, uint _amount) external;
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function principlabalance(address _user) external view returns (uint256);
    function _getInterestRate(address _user) external view returns (uint256);
    function _getInterestRate() external view returns (uint256);
}   