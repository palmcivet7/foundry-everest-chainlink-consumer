// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {EverestConsumer} from "../src/EverestConsumer.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MockOperator} from "../test/mocks/MockOperator.sol";

contract DeployEverestConsumer is Script {
    function run() external returns (EverestConsumer, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (address _link, address _oracle, string memory _jobId, uint256 _oraclePayment, string memory _signUpURL) =
            helperConfig.activeNetworkConfig();

        vm.startBroadcast();
        EverestConsumer everestConsumer = new EverestConsumer(
            _link, _oracle, _jobId, _oraclePayment, _signUpURL
        );
        if (helperConfig.usedAnvilEthConfig()) {
            MockOperator(_oracle).setConsumerAddress(address(everestConsumer)); // Set EverestConsumer address in MockOperator only if getOrCreateAnvilEthConfig was used.
        }
        vm.stopBroadcast();

        return (everestConsumer, helperConfig);
    }
}
