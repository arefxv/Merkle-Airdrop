//SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {AirdropToken} from "src/AirdropToken.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

contract MerkleAirdropTest is Test {
    DeployMerkleAirdrop deployer;
    MerkleAirdrop airdrop;
    AirdropToken token;

    address user;
    uint256 userPrivateKey;
    address gasPayer;

    uint256 amountToCollect = 25e18;
    uint256 amountToSend = amountToCollect * 4;

    bytes32 public constant ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32 public proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 public proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public proof = [proofOne, proofTwo];

    bytes32 invalid_proof_one = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 invalid_proof_two = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32[] invalidProof = [invalid_proof_one, invalid_proof_two];

    function setUp() external {
        deployer = new DeployMerkleAirdrop();
        token = new AirdropToken();
        airdrop = new MerkleAirdrop(ROOT, token);

        token.mint(token.owner(), amountToSend);
        token.transfer(address(airdrop), amountToSend);

        (user, userPrivateKey) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }

    function signMessage(uint256 privateKey, address account) public view returns (uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, amountToCollect);
        (v, r, s) = vm.sign(privateKey, hashedMessage);
    }

    function testConstructorInitializesRoot() public view {
        bytes32 expectedRoot = ROOT;
        bytes32 actualRoot = airdrop.getMerkleRoot();

        assert(actualRoot == expectedRoot);
    }

    function testConstructorInitializesTheToken() public view {
        IERC20 expectedToken = IERC20(token);
        IERC20 actualToken = airdrop.getAirdropToken();

        assert(actualToken == expectedToken);
    }

    function testClaimFailsIfUserAlreadyClaimed() public {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.startPrank(gasPayer);
        airdrop.claim(user, amountToCollect, proof, v, r, s);
        vm.stopPrank();

        console.log("user's balance : ", token.balanceOf(user));
        console.log("user's gas payer: ", token.balanceOf(gasPayer));

        vm.prank(gasPayer);
        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__AlreadyClaimed.selector);
        airdrop.claim(user, amountToCollect, proof, v, r, s);
    }

    function testClaimFailsIfSignatureIsNotValid() public {
        bytes32 digest = airdrop.getMessageHash(user, amountToCollect);

        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, gasPayer);
        airdrop.getSignature(gasPayer, digest, v, r, s);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidSignature.selector);
        airdrop.claim(user, amountToCollect, proof, v, r, s);
    }

    function testClaimFailsIfProofIsNotValid() public {
        vm.prank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);

        airdrop.getProof(user, amountToCollect, invalidProof);

        vm.expectRevert(MerkleAirdrop.MerkleAirdrop__InvalidProof.selector);

        airdrop.claim(user, amountToCollect, invalidProof, v, r, s);
    }

    modifier signedAndClaimed() {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);

        airdrop.claim(user, amountToCollect, proof, v, r, s);
        vm.stopPrank();
        _;
    }

    function testUsersAddToArrayOfClaimers() public signedAndClaimed {

        bool claimedSuccessfully = airdrop.getClaimedUsers(user);

        assert(claimedSuccessfully == true);
    }

    function testGaspayerCanClaimForUser() public {
        vm.startPrank(user);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(userPrivateKey, user);
        vm.stopPrank();

        vm.prank(gasPayer);
        airdrop.claim(user, amountToCollect, proof, v, r, s);

        uint256 expectedUserBalance = amountToCollect;
        uint256 expectedGasPayerBalance = 0;
        uint256 actualUserBalance = token.balanceOf(user);

        assert(expectedUserBalance == actualUserBalance);
        assert(expectedGasPayerBalance == 0);
    }
}
