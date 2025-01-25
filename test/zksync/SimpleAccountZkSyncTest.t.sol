// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test, console2 } from "forge-std/Test.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { SimpleAccountZkSync } from "../../src/zksync/SimpleAccountZkSync.sol";
import { Transaction } from "@era-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import { MemoryTransactionHelper } from
    "@era-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import { BOOTLOADER_FORMAL_ADDRESS } from "@era-contracts/contracts/Constants.sol";
import { ACCOUNT_VALIDATION_SUCCESS_MAGIC } from "@era-contracts/contracts/interfaces/IAccount.sol";

bytes32 constant EMPTY_BYTES = bytes32(0);
string constant MNEMONIC = "test test test test test test test test test test test junk";

contract SimpleAccountZkSyncTest is Test {
    using MemoryTransactionHelper for Transaction;

    SimpleAccountZkSync simpleAccountZkSync;
    ERC20Mock usdc;
    address accountOwner;

    function setUp() external {
        (accountOwner,) = deriveRememberKey(MNEMONIC, 0);

        simpleAccountZkSync = new SimpleAccountZkSync();
        usdc = new ERC20Mock();

        vm.deal(accountOwner, 2 ether);
        simpleAccountZkSync.transferOwnership(accountOwner);
        console2.log("chainid : ", block.chainid);
    }

    function testOwnerCanExecuteTx() external {
        address dest = address(usdc);
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeCall(ERC20Mock.mint, (address(simpleAccountZkSync), amountToMint));

        Transaction memory transaction =
            _createTransaction(113, accountOwner, dest, value, functionData);

        vm.prank(accountOwner);
        simpleAccountZkSync.executeTransaction(EMPTY_BYTES, EMPTY_BYTES, transaction);

        assertEq(usdc.balanceOf(address(simpleAccountZkSync)), amountToMint);
    }

    function testValidateTx() external {
        address dest = address(usdc);
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeCall(ERC20Mock.mint, (address(simpleAccountZkSync), amountToMint));

        Transaction memory transaction =
            _createTransaction(113, accountOwner, dest, value, functionData);

        bytes memory signature = _signTransaction(transaction, accountOwner);
        transaction.signature = signature;

        vm.prank(accountOwner);
        (bool success,) = address(simpleAccountZkSync).call{ value: 1 ether }("");
        assert(success);

        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic =
            simpleAccountZkSync.validateTransaction(EMPTY_BYTES, EMPTY_BYTES, transaction);

        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);
    }

    function testBootloaderCanExecuteTx() external {
        address dest = address(usdc);
        uint256 value = 0;
        uint256 amountToMint = 1_000_000 * 1e18;

        bytes memory functionData =
            abi.encodeCall(ERC20Mock.mint, (address(simpleAccountZkSync), amountToMint));

        Transaction memory transaction =
            _createTransaction(113, accountOwner, dest, value, functionData);

        bytes memory signature = _signTransaction(transaction, accountOwner);
        transaction.signature = signature;

        vm.prank(accountOwner);
        (bool success,) = address(simpleAccountZkSync).call{ value: 1 ether }("");
        assert(success);

        console2.log("Owner's balance before : ,", accountOwner.balance);

        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic =
            simpleAccountZkSync.validateTransaction(EMPTY_BYTES, EMPTY_BYTES, transaction);

        assertEq(magic, ACCOUNT_VALIDATION_SUCCESS_MAGIC);

        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        simpleAccountZkSync.executeTransaction(EMPTY_BYTES, EMPTY_BYTES, transaction);

        console2.log("Owner's balance later : ,", accountOwner.balance);
        console2.log("SimpleAccountZk balance later : ,", address(simpleAccountZkSync).balance);
        console2.log("Bootloader balance later : ,", BOOTLOADER_FORMAL_ADDRESS.balance);

        assertEq(usdc.balanceOf(address(simpleAccountZkSync)), amountToMint);
    }

    function testDeploy() external view {
        assertNotEq(address(simpleAccountZkSync), address(0));
        assertNotEq(address(usdc), address(0));
    }

    function _createTransaction(
        uint256 txType,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) private view returns (Transaction memory) {
        uint256 nonce = vm.getNonce(simpleAccountZkSync.owner());
        bytes32[] memory factoryDeps = new bytes32[](0);

        return Transaction({
            txType: txType,
            from: uint256(uint160(from)),
            to: uint256(uint160(to)),
            gasLimit: 16777216,
            gasPerPubdataByteLimit: 16777216,
            maxFeePerGas: 16777216,
            maxPriorityFeePerGas: 16777216,
            paymaster: 0,
            nonce: nonce,
            value: value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: data,
            signature: hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"",
            reservedDynamic: hex""
        });
    }

    function _signTransaction(Transaction memory transaction, address account)
        private
        view
        returns (bytes memory)
    {
        bytes32 digest = transaction.encodeHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(account, digest);

        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }
}
