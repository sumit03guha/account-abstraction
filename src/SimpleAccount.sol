// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { IAccount } from "account-abstraction/contracts/interfaces/IAccount.sol";

import { PackedUserOperation } from
    "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {
    SIG_VALIDATION_SUCCESS,
    SIG_VALIDATION_FAILED
} from "account-abstraction/contracts/core/Helpers.sol";

import { SimpleAccount__NotOwnerOrEntryPoint } from "./Errors.sol";
import { SimpleAccount__NotEntryPoint } from "./Errors.sol";
import { SimpleAccount__ExecutionFailed } from "./Errors.sol";

contract SimpleAccount is IAccount, Ownable {
    address private immutable _entryPoint;

    constructor(address entryPoint) Ownable(msg.sender) {
        _entryPoint = entryPoint;
    }

    receive() external payable { }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        _requireEntryPointOrOwner();
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        if (owner() != ECDSA.recover(ethSignedMessageHash, userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
        _payPrefund(missingAccountFunds);

        return SIG_VALIDATION_SUCCESS;
    }

    function execute(address dest, uint256 value, bytes memory functionData) external {
        _requireEntryPointOrOwner();

        (bool success, bytes memory data) = dest.call{ value: value }(functionData);
        if (!success) revert SimpleAccount__ExecutionFailed(data);
    }

    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        if (missingAccountFunds != 0) {
            (bool success,) =
                payable(msg.sender).call{ value: missingAccountFunds, gas: type(uint256).max }("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    function _requireEntryPointOrOwner() private view {
        if ((msg.sender != owner()) && (msg.sender != _entryPoint)) {
            revert SimpleAccount__NotOwnerOrEntryPoint();
        }
    }

    function _requireEntryPoint() private view {
        if (msg.sender != _entryPoint) {
            revert SimpleAccount__NotEntryPoint();
        }
    }
}
