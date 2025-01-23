// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "@era-contracts/contracts/interfaces/IAccount.sol";
import { INonceHolder } from "@era-contracts/contracts/interfaces/INonceHolder.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "@era-contracts/contracts/Constants.sol";
import { Transaction } from "@era-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import { SystemContractsCaller } from "@era-contracts/contracts/libraries/SystemContractsCaller.sol";
import { MemoryTransactionHelper } from
    "@era-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import { Utils } from "@era-contracts/contracts/libraries/Utils.sol";

import {
    SimpleAccountZkSync__OutOfBalance,
    SimpleAccountZkSync__NotFromBootloader,
    SimpleAccountZkSync__ExecutionFailed
} from "./Errors.sol";

contract SimpleAccountZkSync is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    constructor() Ownable(msg.sender) { }

    function validateTransaction(
        bytes32 _txHash,
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable returns (bytes4 magic) {
        _requireFromBootloader();

        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, _transaction.nonce)
        );

        if (address(this).balance < _transaction.totalRequiredBalance()) {
            revert SimpleAccountZkSync__OutOfBalance();
        }

        bytes32 digest = _transaction.encodeHash();
        address signer = ECDSA.recover(digest, _transaction.signature);
        bool isValidSigner = signer == owner();

        if (isValidSigner) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    function executeTransaction(
        bytes32 _txHash,
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            SystemContractsCaller.systemCallWithPropagatedRevert(uint32(gasleft()), to, value, data);
        } else {
            bool success;

            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }

            if (!success) {
                revert SimpleAccountZkSync__ExecutionFailed();
            }
        }
    }

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable { }

    function payForTransaction(
        bytes32 _txHash,
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable { }

    function prepareForPaymaster(
        bytes32 _txHash,
        bytes32 _possibleSignedHash,
        Transaction calldata _transaction
    ) external payable { }

    function _requireFromBootloader() private view {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert SimpleAccountZkSync__NotFromBootloader();
        }
    }
}
