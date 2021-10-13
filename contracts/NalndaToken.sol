// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NalndaToken is Context, ERC20 {
    constructor() ERC20("Nalnda", "NLD") {
        _mint(_msgSender(), 10000 * (10**uint256(decimals())));
    }
}
