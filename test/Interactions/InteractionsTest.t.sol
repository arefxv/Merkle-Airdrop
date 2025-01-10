// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {ClaimAirdrop} from "script/Integrations/Interactions.s.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {AirdropToken} from "src/AirdropToken.sol";


contract InteractionsTest is Test {
    ClaimAirdrop claim;

    function setUp() external {
        claim = new ClaimAirdrop();
        
    }

    function testSplitValidSignature() public view{
        bytes32 r = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
        bytes32 s = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
        uint8 v = 27;

        bytes memory signature = abi.encodePacked(r, s, v);

        (uint8 actual_v, bytes32 actual_r, bytes32 actual_s) = claim.splitSignature(signature);

        assertEq(actual_r , r);
        assertEq(actual_s , s);
        assertEq(actual_v, v);
    }
    
    function testSplitInvalidSignatureReverts() public {
        bytes memory invalidSig = new bytes(64);

        vm.expectRevert();
        claim.splitSignature(invalidSig);
    }
 
}

