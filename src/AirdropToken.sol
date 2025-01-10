// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

/**
 * @title AirdropToken
 * @author ArefXV
 * @dev A basic ERC20 token with minting functionality, intended for use in airdrop distributions.
 *      - Inherits from OpenZeppelin's ERC20 and Ownable contracts.
 *      - The contract owner has exclusive rights to mint tokens.
 * @dev The `mint` function allows the owner to create new tokens and assign them to a specific account.
 * @dev This contract is ideal for testing or implementing token airdrops, where a designated owner controls token supply.
 */
contract AirdropToken is ERC20, Ownable {
    /**
     * @notice Initializes the token with a name, symbol, and sets the deployer as the owner.
     * @dev Inherits the `Ownable` constructor, assigning ownership to the deployer.
     */
    constructor() ERC20("Airdrop Token", "AT") Ownable(msg.sender) {}

    /**
     * @notice Mints new tokens and assigns them to the specified account.
     * @param account The address to receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @dev Restricted to the contract owner by the `onlyOwner` modifier.
     * @dev The `_mint` function is inherited from OpenZeppelin's ERC20 implementation.
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}
