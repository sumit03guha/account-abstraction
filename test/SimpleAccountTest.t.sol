// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test, console2 } from "forge-std/Test.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from
    "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {
    SIG_VALIDATION_SUCCESS,
    SIG_VALIDATION_FAILED
} from "account-abstraction/contracts/core/Helpers.sol";

import { SimpleAccount } from "../src/SimpleAccount.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { NetworkConfig } from "../script/NetworkConfig.sol";
import { DeploySimpleAccount } from "../script/DeploySimpleAccount.s.sol";
import { PackedUserOps } from "../script/PackedUserOps.s.sol";
import { SimpleAccount__NotOwnerOrEntryPoint } from "../src/Errors.sol";

contract SimpleAccountTest is Test {
    SimpleAccount simpleAccount;
    HelperConfig helperConfig;
    DeploySimpleAccount deploySimpleAccount;
    NetworkConfig networkConfig;
    PackedUserOps packedUserOps;
    ERC20Mock usdc;

    function setUp() external {
        deploySimpleAccount = new DeploySimpleAccount();
        (simpleAccount, helperConfig) = deploySimpleAccount.deploySimpleAccount();
        networkConfig = helperConfig.getConfig();
        packedUserOps = new PackedUserOps();

        usdc = ERC20Mock(networkConfig.usdc);

        vm.deal(networkConfig.account, 10 ether);
    }

    function testOwnerCanExecuteTx() external {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        vm.prank(networkConfig.account);
        simpleAccount.execute(dest, value, functionData);

        assertEq(usdc.balanceOf(address(simpleAccount)), amountToMint);
    }

    function testMaliciousAddressCannotExecuteTx() external {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        address randomAddress = makeAddr("Malicious Random Address");
        vm.prank(randomAddress);
        vm.expectRevert(SimpleAccount__NotOwnerOrEntryPoint.selector);
        simpleAccount.execute(dest, value, functionData);
    }

    function testValidateUserOp() external {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        bytes memory executeCallData =
            abi.encodeWithSelector(SimpleAccount.execute.selector, dest, value, functionData);

        (PackedUserOperation memory packedUserOperation, bytes32 userOpsHash, bytes32 digest) =
        packedUserOps.generateSignedPackedUserOps(
            networkConfig.entryPoint, networkConfig.account, address(simpleAccount), executeCallData
        );

        address recovered = ECDSA.recover(digest, packedUserOperation.signature);

        assertEq(recovered, networkConfig.account);

        uint256 missingAccountFunds = 0;

        vm.prank(networkConfig.entryPoint);
        uint256 result =
            simpleAccount.validateUserOp(packedUserOperation, userOpsHash, missingAccountFunds);

        assertEq(result, SIG_VALIDATION_SUCCESS);
    }

    function testEntryPointCanExecute() external {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        bytes memory executeCallData =
            abi.encodeWithSelector(SimpleAccount.execute.selector, dest, value, functionData);

        (PackedUserOperation memory packedUserOperation,, bytes32 digest) = packedUserOps
            .generateSignedPackedUserOps(
            networkConfig.entryPoint, networkConfig.account, address(simpleAccount), executeCallData
        );

        address recovered = ECDSA.recover(digest, packedUserOperation.signature);

        assertEq(recovered, networkConfig.account);

        vm.prank(networkConfig.account);
        (bool success,) = payable(address(simpleAccount)).call{ value: 1 ether }("");
        assert(success);

        assertEq(address(simpleAccount).balance, 1 ether);

        address randomUserFromAltMempool = makeAddr("randomUserFromAltMempool");
        uint256 randomUserFromAltMempoolEthBalanceBeforeTx = randomUserFromAltMempool.balance;
        console2.log(
            "randomUserFromAltMempool eth balance before tx: ",
            randomUserFromAltMempoolEthBalanceBeforeTx
        );

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOperation;

        vm.prank(randomUserFromAltMempool);
        IEntryPoint(networkConfig.entryPoint).handleOps(ops, payable(randomUserFromAltMempool));

        uint256 randomUserFromAltMempoolEthBalanceAfterTx = randomUserFromAltMempool.balance;
        console2.log(
            "randomUserFromAltMempool eth balance before tx: ",
            randomUserFromAltMempoolEthBalanceAfterTx
        );

        console2.log("SimpleAccount eth balance : ", (address(simpleAccount).balance));

        assertGt(
            randomUserFromAltMempoolEthBalanceAfterTx, randomUserFromAltMempoolEthBalanceBeforeTx
        );
        assertLt(address(simpleAccount).balance, 1 ether);
        assertEq(usdc.balanceOf(address(simpleAccount)), amountToMint);
    }

    function testDeploy() external view {
        assertNotEq(address(simpleAccount), address(0));
        assertNotEq(networkConfig.account, address(0));
        assertNotEq(networkConfig.entryPoint, address(0));
        assertNotEq(networkConfig.usdc, address(0));
        assertEq(simpleAccount.owner(), networkConfig.account);
    }

    function testRecoverSignedOp() external view {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        bytes memory executeCallData =
            abi.encodeWithSelector(SimpleAccount.execute.selector, dest, value, functionData);

        (PackedUserOperation memory packedUserOperation,, bytes32 digest) = packedUserOps
            .generateSignedPackedUserOps(
            networkConfig.entryPoint, networkConfig.account, address(simpleAccount), executeCallData
        );

        address recovered = ECDSA.recover(digest, packedUserOperation.signature);

        assertEq(recovered, networkConfig.account);
    }
}
