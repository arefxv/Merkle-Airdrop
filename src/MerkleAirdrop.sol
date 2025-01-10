// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20, SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/utils/cryptography/EIP712.sol";
import {MerkleProof} from "@openzeppelin/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleAirdrop
 * @author ArefXV
 * @dev Implements a token airdrop using Merkle tree for efficient proof verification, ECDSA for secure signature recovery, and EIP712 for structured data signing.
 * @dev Users can allow trusted individuals to claim their airdrop by signing a message, enabling gas fee payment by the claimant.
 * @dev Only users included in the Merkle tree's leaf nodes can claim the airdrop.
 * @dev The addresses of eligible users are registered using the `GenerateInput.s.sol` script.
 * @dev The Merkle tree is generated and deployed using the `MakeMerkle.s.sol` script.
 */
contract MerkleAirdrop is EIP712 {
    using ECDSA for bytes32;
    using MerkleProof for bytes32;
    using SafeERC20 for IERC20;

    /*////////////////////////////////////////////////
                          ERRORS
    ////////////////////////////////////////////////*/

    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();
    error MerkleAirdrop__InvalidProof();

    /*////////////////////////////////////////////////
                        STRUCTS
    ////////////////////////////////////////////////*/

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    /*////////////////////////////////////////////////
                    STATE VARIABLES
    ////////////////////////////////////////////////*/

    // MESSAGE_TYPEHASH: A constant used to define the structured data type for EIP-712 signature verification.
    // Represents the structure: AirdropClaim(address account, uint256 amount).
    // This ensures compatibility with off-chain signing and on-chain verification processes
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;

    // Mapping to track whether an address has claimed its airdrop tokens.
    // Used to prevent double claiming.
    mapping(address user => bool claimed) private s_alreadyClaimed;

    /*////////////////////////////////////////////////
                         EVENTS
    ////////////////////////////////////////////////*/

    /**
     * @dev Emitted when a user successfully claims their airdrop.
     * @param user The address of the user who claimed the airdrop.
     * @param amount The amount of tokens claimed.
     */
    event Claimed(address indexed user, uint256 indexed amount);

    /*////////////////////////////////////////////////
                    SPECIAL FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with the Merkle root and airdrop token.
     * @param merkleRoot The root of the Merkle tree.
     * @param airdropToken The ERC20 token to be distributed.
     */
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("Merkle Airdrop", "1.0.0") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /*////////////////////////////////////////////////
                    EXTERNAL FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @notice Allows users or their trusted designees to claim their airdrop.
     * @param account The address of the claimant.
     * @param amount The amount to claim.
     * @param merkleProof The Merkle proof for verification.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature.
     * @param s Half of the ECDSA signature.
     * @dev The function ensures:
     * 1. The user has not claimed before (checked via `s_alreadyClaimed`).
     * 2. The EIP-712 signature is valid and matches the claim parameters.
     * 3. The Merkle proof verifies the user's inclusion in the Merkle tree.
     * After passing checks, the user's claim status is updated, and tokens are transferred.
     * @dev Follows the Checks-Effects-Interactions (CEI) pattern to prevent reentrancy.
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_alreadyClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }

        if (!_isValidProof(account, amount, merkleProof)) {
            revert MerkleAirdrop__InvalidProof();
        }

        s_alreadyClaimed[account] = true;
        emit Claimed(account, amount);

        i_airdropToken.safeTransfer(account, amount);
    }

    /*////////////////////////////////////////////////
                     PUBLIC FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @notice Computes the EIP712 hash of the claim message.
     * @param account The address of the user.
     * @param amount The amount of tokens to claim.
     * @return The hashed claim message.
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    /*////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @notice Verifies that the signature matches the provided digest and signer.
     * @param signer The address of the signer.
     * @param digest The hashed message digest.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature.
     * @param s Half of the ECDSA signature.
     * @return True if the signature is valid, false otherwise.
     */
    function _isValidSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);

        return (actualSigner == signer);
    }

    /**
     * @notice Verifies the Merkle proof for the given account and amount.
     * @param account The address of the user.
     * @param amount The amount of tokens to claim.
     * @param merkleProof The Merkle proof for the user.
     * @return True if the proof is valid, false otherwise.
     */
    function _isValidProof(address account, uint256 amount, bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        bool isValid = MerkleProof.verify(merkleProof, i_merkleRoot, leaf);
        return isValid;
    }

    /*////////////////////////////////////////////////
                    GETTER FUNCTIONS
    ////////////////////////////////////////////////*/

    /**
     * @dev Getter functions for accessing state variables and internal function arguments, useful for testing and debugging.
     * Each function's functionality is explained below:
     * - getMerkleRoot: Returns the Merkle root of the tree generated in the contract.
     * - getAirdropToken: Retrieves the address of the token being airdropped (if applicable).
     * - getMessageTypeHash: Provides the type hash used for EIP-712 signature verification.
     * - getClaimedUsers: Returns the list of addresses that have already claimed their tokens.
     * - getSignature: Retrieves the stored or expected signature for verifying claims.
     * - getProof: Returns the Merkle proof for a given leaf, used to verify inclusion in the Merkle tree.
     */

    /**
     * @notice Returns the root of the Merkle tree used for verifying airdrop claims.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /**
     * @notice Retrieves the ERC20 token being airdropped in this contract.
     */
    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }

    /**
     * @notice Provides the constant type hash used for EIP-712 structured data signing.
     */
    function getMessageTypeHash() external pure returns (bytes32) {
        return MESSAGE_TYPEHASH;
    }

    /**
     * @notice Checks if a user has already claimed their airdrop tokens.
     * @param user The address of the user to check.
     * @return True if the user has already claimed, false otherwise.
     */
    function getClaimedUsers(address user) external view returns (bool) {
        return s_alreadyClaimed[user];
    }

    /**
     * @notice Validates a signature using the internal function.
     * @param signer The address of the signer.
     * @param digest The hashed message digest.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature.
     * @param s Half of the ECDSA signature.
     * @return True if the signature is valid, false otherwise.
     */
    function getSignature(address signer, bytes32 digest, uint8 v, bytes32 r, bytes32 s) external pure returns (bool) {
        return _isValidSignature(signer, digest, v, r, s);
    }

    /**
     * @notice Validates a Merkle proof using the internal function.
     * @param account The address of the user.
     * @param amount The amount of tokens to claim.
     * @param merkleProof The Merkle proof.
     * @return True if the proof is valid, false otherwise.
     */
    function getProof(address account, uint256 amount, bytes32[] calldata merkleProof) external view returns (bool) {
        return _isValidProof(account, amount, merkleProof);
    }
}
