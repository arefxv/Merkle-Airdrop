// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {AirdropToken} from "src/AirdropToken.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/**
 * @title ClaimAirdrop Script
 * @author ArefXV
 * @notice This script automates the process of claiming an airdrop using the MerkleAirdrop contract.
 *         It verifies proofs and signatures to ensure valid claims.
 * @dev Uses Foundry's `Script` library to interact with blockchain during deployment and testing.
 */
contract ClaimAirdrop is Script {
    /// @notice Custom error for invalid signature lengths.
    error Integrations__ClaimAirdrop__InvalidSignatureLength();

    /// @dev Signature to authenticate the claim (placeholder, should be replaced with the actual signature).
    bytes constant SIGNATURE = hex"";

    /// @dev The address of the user claiming the airdrop.
    address constant CLAIMER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    /// @dev The amount of tokens to be claimed.
    uint256 constant CLAIM_AMOUNT = 25e18;

    /// @dev Proof elements for Merkle tree verification.
    bytes32 constant PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 constant PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];

    /**
     * @notice Claims tokens from the MerkleAirdrop contract.
     * @param merkleAirdropContractAddress The address of the MerkleAirdrop contract.
     * @dev Splits the provided signature into its components and submits the claim.
     */
    function claimAirdrop(address merkleAirdropContractAddress) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(merkleAirdropContractAddress).claim(CLAIMER, CLAIM_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    /**
     * @notice Splits a given signature into its `v`, `r`, and `s` components.
     * @param sig The signature to be split.
     * @return v Recovery identifier.
     * @return r First 32 bytes of the signature.
     * @return s Second 32 bytes of the signature.
     * @dev Ensures the provided signature has a length of 65 bytes.
     * @dev Uses inline assembly for low-level memory manipulation.
     */
    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert Integrations__ClaimAirdrop__InvalidSignatureLength();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @notice Entry point for the script execution.
     * @dev Fetches the most recently deployed MerkleAirdrop contract and calls `claimAirdrop`.
     */
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }
}
