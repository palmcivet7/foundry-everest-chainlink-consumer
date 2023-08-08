// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EverestConsumer} from "../src/EverestConsumer.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployEverestConsumer is Script {
    function run() external returns (EverestConsumer, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address link, address _oracle, string _jobId, uint256 _oraclePayment, string _signUpURL) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        EverestConsumer everestConsumer = new EverestConsumer(
            link, _oracle, jobId, _oraclePayment, _signUpURL
        );
        vm.stopBroadcast();

        return (everestConsumer, helperConfig);
    }
}
