// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Script } from "forge-std/Script.sol";

import { SimpleAccount } from "../src/SimpleAccount.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { NetworkConfig } from "./NetworkConfig.sol";

contract DeploySimpleAccount is Script {
    function run() external {
        deploySimpleAccount();
    }

    function deploySimpleAccount() public returns (SimpleAccount, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        NetworkConfig memory networkConfig = helperConfig.getConfig();

        vm.startBroadcast();
        SimpleAccount simpleAccount = new SimpleAccount(networkConfig.entryPoint);
        simpleAccount.transferOwnership(networkConfig.account);

        vm.stopBroadcast();

        return (simpleAccount, helperConfig);
    }
}
