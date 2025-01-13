// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";

import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";

import { HelperConfig__InvalidChainId } from "../src/Errors.sol";
import { NetworkConfig } from "./NetworkConfig.sol";

contract HelperConfig is Script {
    uint256 private constant _ANVIL_CHAIN_ID = 31337;
    uint256 private constant _SEPOLIA_CHAIN_ID = 11155111;
    uint256 private constant _ZKSYNC_CHAIN_ID = 300;

    address private constant _ENTRY_POINT_SEPOLIA_ADDRESS =
        0x0576a174D229E3cFA37253523E645A78A0C91B57;
    address private constant _USDC_SEPOLIA_ADDRESS = 0x0576a174D229E3cFA37253523E645A78A0C91B57;

    NetworkConfig private _localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) private _networConfigs;

    // address private _dummyAccount = makeAddr("DUMMY_ACCOUNT");

    function getConfig() external returns (NetworkConfig memory) {
        return _getConfigByChainId(block.chainid);
    }

    function _getConfigByChainId(uint256 chainId) private returns (NetworkConfig memory) {
        if (chainId == _ANVIL_CHAIN_ID) {
            return _getOrDeployAnvilChainConfig();
        } else if (chainId == _SEPOLIA_CHAIN_ID) {
            return _getSepoliaConfig();
        } else if (chainId == _ZKSYNC_CHAIN_ID) {
            return _getZkSyncConfig();
        } else {
            revert HelperConfig__InvalidChainId(chainId);
        }
    }

    function _getOrDeployAnvilChainConfig() private returns (NetworkConfig memory) {
        if (_localNetworkConfig.entryPoint != address(0)) return _localNetworkConfig;

        string memory mnemonic = "test test test test test test test test test test test junk";

        (address deployer,) = deriveRememberKey(mnemonic, 0);

        vm.startBroadcast(deployer);

        EntryPoint entryPoint = new EntryPoint();
        ERC20Mock erc20Mock = new ERC20Mock();

        vm.stopBroadcast();

        _localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: deployer,
            usdc: address(erc20Mock)
        });

        return _localNetworkConfig;
    }

    function _getSepoliaConfig() private view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: _ENTRY_POINT_SEPOLIA_ADDRESS,
            account: address(0),
            usdc: _USDC_SEPOLIA_ADDRESS
        });
    }

    function _getZkSyncConfig() private view returns (NetworkConfig memory) {
        return NetworkConfig({ entryPoint: address(0), account: address(0), usdc: address(0) });
    }
}
