// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { PackedUserOperation } from
    "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

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
    }

    function testDeploy() external {
        assertNotEq(address(simpleAccount), address(0));
        assertNotEq(networkConfig.account, address(0));
        assertNotEq(networkConfig.entryPoint, address(0));
        assertNotEq(networkConfig.usdc, address(0));
        assertEq(simpleAccount.owner(), networkConfig.account);
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

    function testFailMaliciousAddressCannotExecuteTx() external {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        address randomAddress = makeAddr("Malicious Random Address");
        vm.prank(randomAddress);
        vm.expectRevert(abi.encode(SimpleAccount__NotOwnerOrEntryPoint.selector));
        simpleAccount.execute(dest, value, functionData);
    }

    function testRecoverSignedOp() external {
        address dest = networkConfig.usdc;
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeWithSelector(ERC20Mock.mint.selector, address(simpleAccount), amountToMint);

        bytes memory executeCallData =
            abi.encodeWithSelector(SimpleAccount.execute.selector, dest, value, functionData);

        (PackedUserOperation memory packedUserOperation, bytes32 digest) = packedUserOps
            .generateSignedPackedUserOps(
            networkConfig.entryPoint, networkConfig.account, executeCallData
        );

        address recovered = ECDSA.recover(digest, packedUserOperation.signature);

        assertEq(recovered, networkConfig.account);
    }
}
