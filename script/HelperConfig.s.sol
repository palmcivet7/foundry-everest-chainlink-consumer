// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
// import {MockOperator} from "../test/mocks/MockOperator.sol";
import {Operator} from "../test/operator-mocks/Operator.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address _link;
        address _oracle;
        string _jobId;
        uint256 _oraclePayment;
        string _signUpURL;
    }

    NetworkConfig public activeNetworkConfig;
    bool public usedAnvilEthConfig = false;

    constructor() {
        if (block.chainid == 137) {
            activeNetworkConfig = getPolygonConfig();
        } else if (block.chainid == 5) {
            activeNetworkConfig = getGoerliEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getPolygonConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            _link: 0xb0897686c545045aFc77CF20eC7A532E3120E0F1,
            _oracle: 0x97b6Df5808b7f46Ee2C0e482E1B785CE3A2BC8BF,
            _jobId: "827352c4d8684571b4605f9022853ddf",
            _oraclePayment: 100000000000000000,
            _signUpURL: "https://wallet.everest.org"
        });
    }

    function getGoerliEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            _link: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            _oracle: 0xB9756312523826A566e222a34793E414A81c88E1,
            _jobId: "14f849816fac426abda2992cbf47d2cd",
            _oraclePayment: 100000000000000000,
            _signUpURL: "https://wallet.everest.org"
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        usedAnvilEthConfig = true;
        vm.startBroadcast();
        LinkToken link = new LinkToken();
        // MockOperator oracle = new MockOperator(address(link));
        Operator oracle = new Operator(address(link), msg.sender);
        vm.stopBroadcast();
        return NetworkConfig({
            _link: address(link),
            _oracle: address(oracle),
            _jobId: "509e8dd8de054d3f918640ab0a2b77d8",
            _oraclePayment: 100000000000000000,
            _signUpURL: "https://wallet.everest.org"
        });
    }
}
