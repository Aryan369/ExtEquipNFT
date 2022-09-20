// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@rmrk-team/evm-contracts/contracts/implementations/RMRKBaseStorageImpl.sol";

contract Base is RMRKBaseStorageImpl {
    constructor(
        string memory symbol,
        string memory type_
    ) RMRKBaseStorageImpl(symbol, type_) {}
}