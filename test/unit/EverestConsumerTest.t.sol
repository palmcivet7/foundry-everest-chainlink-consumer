// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployEverestConsumer} from "../../script/DeployEverestConsumer.s.sol";
import {EverestConsumer} from "../../src/EverestConsumer.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract EverestConsumerTest is Test {
    EverestConsumer everestConsumer;
    HelperConfig helperConfig;

    address _link;
    address _oracle;
    string _jobId;
    uint256 _oraclePayment;
    string _signUpURL;

    address public USER = makeAddr("USER");
    address public BOB = makeAddr("BOB");
    uint256 public constant STARTING_USER_BALANCE = 1000 ether; // 1000 LINK

    function setUp() external {
        DeployEverestConsumer deployer = new DeployEverestConsumer();
        (everestConsumer, helperConfig) = deployer.run();
        (_link, _oracle, _jobId, _oraclePayment, _signUpURL) = helperConfig.activeNetworkConfig();
        vm.deal(USER, STARTING_USER_BALANCE);
        ERC20Mock(_link).mint(USER, STARTING_USER_BALANCE);
    }

    function testConstructorPropertiesSetCorrectly() public {
        assertNotEq(everestConsumer.oracleAddress(), address(0));
        assertNotEq(address(everestConsumer), address(0));

        assertEq(everestConsumer.oracleAddress(), _oracle);
        assertEq(everestConsumer.jobId(), bytes32(abi.encodePacked(_jobId)));
        assertEq(everestConsumer.oraclePayment(), _oraclePayment);
        assertEq(everestConsumer.linkAddress(), _link);
        assertEq(everestConsumer.signUpURL(), _signUpURL);
    }

    ///////////////////////
    ///// setOracle //////
    /////////////////////

    function testSetOracleShouldSetProperlyWithOwnerSender() public {
        vm.startPrank(msg.sender);
        everestConsumer.setOracle(USER);
        vm.stopPrank();
        assertEq(everestConsumer.oracleAddress(), address(USER));
    }

    function testSetOracleShouldRevertIfSenderIsNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        everestConsumer.setOracle(BOB);
        vm.stopPrank();
    }

    //////////////////////////////
    ///// setOraclePayment //////
    ////////////////////////////

    function testSetOraclePaymentShouldSetProperlyWithOwnerSender() public {
        vm.startPrank(msg.sender);
        everestConsumer.setOraclePayment(1);
        vm.stopPrank();
        assertEq(everestConsumer.oraclePayment(), 1);
    }

    function testSetOraclePaymentShouldRevertIfSenderIsNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        everestConsumer.setOraclePayment(1);
        vm.stopPrank();
    }

    /////////////////////
    ///// setLink //////
    ///////////////////

    function testSetLinkShouldSetProperlyWithOwnerSender() public {
        vm.startPrank(msg.sender);
        everestConsumer.setLink(BOB);
        vm.stopPrank();
        assertEq(everestConsumer.linkAddress(), address(BOB));
    }

    function testSetLinkShouldRevertIfSenderIsNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        everestConsumer.setLink(BOB);
        vm.stopPrank();
    }

    //////////////////////////////
    ///// setSignUpURL //////////
    ////////////////////////////

    function testSetSignUpURLShouldSetProperlyWithOwnerSender() public {
        vm.startPrank(msg.sender);
        everestConsumer.setSignUpURL("https://wallet.everest.org");
        vm.stopPrank();
        assertEq(everestConsumer.signUpURL(), "https://wallet.everest.org");
    }

    function testSetSignUpURLShouldRevertIfSenderIsNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        everestConsumer.setSignUpURL("https://wallet.everest.org");
        vm.stopPrank();
    }

    //////////////////////
    ///// setJobId //////
    ////////////////////

    function testSetJobIdShouldSetProperlyWithOwnerSender() public {
        vm.startPrank(msg.sender);
        everestConsumer.setJobId("7223acbd01654282865b678924126013");
        vm.stopPrank();
        assertEq(everestConsumer.jobId(), bytes32(abi.encodePacked("7223acbd01654282865b678924126013")));
    }

    function testSetJobIdShouldRevertIfSenderIsNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        everestConsumer.setJobId("7223acbd01654282865b678924126013");
        vm.stopPrank();
    }

    function testSetJobIdRevertsIfInvalidLength() public {
        vm.startPrank(msg.sender);
        vm.expectRevert(EverestConsumer.EverestConsumer__IncorrectLength.selector);
        everestConsumer.setJobId("1");
        vm.stopPrank();
    }
}
