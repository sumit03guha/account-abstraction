// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IAccount } from "@era-contracts/contracts/interfaces/IAccount.sol";
import { Transaction } from "@era-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import { SystemContractsCaller } from "@era-contracts/contracts/libraries/SystemContractsCaller.sol";
import { NONCE_HOLDER_SYSTEM_CONTRACT } from "@era-contracts/contracts/Constants.sol";
import { INonceHolder } from "@era-contracts/contracts/interfaces/INonceHolder.sol";

contract SimpleAccountZkSync is IAccount {
    function validateTransaction(
        bytes32 _txHash,
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable returns (bytes4 magic) {
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, _transaction.nonce)
        );
    }

    function executeTransaction(
        bytes32 _txHash,
        bytes32 _suggestedSignedHash,
        Transaction calldata _transaction
    ) external payable { }

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
}
