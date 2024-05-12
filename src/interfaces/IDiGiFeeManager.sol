// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDiGiFeeManager {
    function getDIGIWithdrawFeesBPS(address sender) external returns (address payable, uint256);
}
