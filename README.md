# Merkle Airdrop Contract

## Overview

The **Merkle Airdrop** smart contract implements an efficient and secure token distribution mechanism using Merkle trees, EIP-712 structured data signing, and ECDSA cryptography. It enables eligible users to claim ERC20 tokens through Merkle proof verification, with optional delegation for trusted claimants to pay gas fees

The project leverages the **Foundry** framework for development, testing, and deployment

## Features

- **Efficient Verification**: Uses Merkle trees to verify claims with minimal storage and gas costs.
- **Secure Signing**: Implements EIP-712 for structured data signing and ECDSA for signature validation.
- **Delegated Claims**: Users can delegate gas payments by signing messages for trusted individuals.
- **Prevent Double Claims**: Tracks claimed status to ensure users cannot claim tokens multiple times.

---

## Contracts

### 1. MerkleAirdrop
- **Purpose**: The main contract for managing and verifying airdrop claims.
- **Key Features**:
  - Verifies claims using Merkle proofs.
  - Validates EIP-712 signatures for delegated claims.
  - Emits events for successful claims.
  - Written in Solidity `^0.8.25`.

#### Methods
- `claim`: Allows users or trusted claimants to claim tokens.
- `getMessageHash`: Generates an EIP-712 hash for a claim message.
- `getMerkleRoot`: Returns the Merkle root for proof validation.
- `getAirdropToken`: Returns the ERC20 token used for the airdrop.

### 2. AirdropToken
- **Purpose**: A simple ERC20 token with minting functionality, designed for airdrop use.
- **Key Features**:
  - Owner-only minting.
  - Compliant with OpenZeppelin's ERC20 and Ownable modules.

---

## Scripts

### Deployment and Merkle Tree Setup
Two utility scripts are provided for managing the airdrop:
- **`GenerateInput.s.sol`**: Prepares user data for Merkle tree generation.
- **`MakeMerkle.s.sol`**: Generates the Merkle tree and computes the root hash.

---

## Development

### Prerequisites
- **Foundry Framework**: Ensure you have [Foundry](https://book.getfoundry.sh/) installed for testing and deployment.

### Installation
1. Clone the repository:
   ```bash
   git clone <https://github.com/arefxv/Merkle-Airdrop>
   cd Merkle-Airdrop


2. Install dependencies:
```bash
forge install
```

### Testing
Run the test suite to validate the contracts:

```bash
forge test
```

### Deployment
Compile and deploy the contracts using Foundry:

```bash
forge build
forge script scripts/DeployMerkleAirdrop.s.sol --broadcast
```
---

## Usage
### Claiming Airdrop
1. Ensure your address is included in the Merkle tree.
2. Use the claim function with the following parameters:
- Your address.
- Claim amount.
- Valid Merkle proof.
- Optional: Signed message for delegated claims.

Example call:

```solidity
claim(account, amount, merkleProof, v, r, s);
```

---


## Security Considerations
- **Reentrancy Protection**: The contract follows the Checks-Effects-Interactions pattern to mitigate reentrancy risks.
- **Signature Validation**: Only valid signatures matching claim parameters are accepted.
- **Double Claims**: Claim status is tracked to prevent duplicate claims.
---

### If you liked this, please follow [**ArefXV**](https://linktr.ee/arefxv)# Merkle-Airdrop
# Merkle-Airdrop
