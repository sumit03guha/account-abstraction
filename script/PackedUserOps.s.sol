// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from
    "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract PackedUserOps is Script {
    function run() external { }

    function generateSignedPackedUserOps(
        address entryPoint,
        address account,
        bytes calldata callData
    ) external view returns (PackedUserOperation memory) {
        PackedUserOperation memory userOps = _generatePackedUserOps(account, callData);
        bytes32 userOpsHash = IEntryPoint(entryPoint).getUserOpHash(userOps);
        bytes memory signature = _signUserOps(userOpsHash, account);
        userOps.signature = signature;

        return userOps;
    }

    function _generatePackedUserOps(address account, bytes calldata callData)
        private
        view
        returns (PackedUserOperation memory)
    {
        uint256 nonce = vm.getNonce(account);

        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: account,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }

    function _signUserOps(bytes32 userOpsHash, address account)
        private
        pure
        returns (bytes memory)
    {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpsHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(account, ethSignedMessageHash);
        bytes memory signature = abi.encode(r, s, v);

        return signature;
    }
}
