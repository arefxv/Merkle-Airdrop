// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {AirdropToken} from "src/AirdropToken.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 constant AMOUNT_TO_TRANSFER = 4 * 25e18; //25 AirdropToken for 4 users

    function deployMerkleAirdrop() public returns (MerkleAirdrop, AirdropToken) {
        vm.startBroadcast();
        AirdropToken token = new AirdropToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(ROOT, IERC20(token));

        token.mint(token.owner(), AMOUNT_TO_TRANSFER);
        IERC20(token).transfer(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();

        return (airdrop, token);
    }

    function run() external returns (MerkleAirdrop, AirdropToken) {
        return deployMerkleAirdrop();
    }
}
