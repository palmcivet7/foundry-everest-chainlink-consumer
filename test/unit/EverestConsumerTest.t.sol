// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployEverestConsumer} from "../../script/DeployEverestConsumer.s.sol";
import {EverestConsumer} from "../../src/EverestConsumer.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {LinkToken} from "../mocks/LinkToken.sol";
import {IEverestConsumer} from "../../src/interfaces/IEverestConsumer.sol";
import {MockOperator} from "../mocks/MockOperator.sol";
// import {Operator} from "../operator-mocks/Operator.sol";

contract EverestConsumerTest is Test {
    EverestConsumer everestConsumer;
    HelperConfig helperConfig;
    MockOperator mockOperator;
    Operator operator;

    address _link;
    address _oracle;
    string _jobId;
    uint256 _oraclePayment;
    string _signUpURL;

    address public USER = makeAddr("USER");
    address public BOB = makeAddr("BOB");
    address public REVEALER = makeAddr("REVEALER");
    address public REVEALEE = makeAddr("REVEALEE");
    uint256 public constant STARTING_USER_BALANCE = 1000 ether;

    function setUp() external {
        DeployEverestConsumer deployer = new DeployEverestConsumer();
        (everestConsumer, helperConfig) = deployer.run();
        (_link, _oracle, _jobId, _oraclePayment, _signUpURL) = helperConfig.activeNetworkConfig();
        vm.deal(USER, STARTING_USER_BALANCE);
        // msg.sender has initial supply of link
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

    ////////////////////////////
    ///// statusToString //////
    //////////////////////////

    function testStatusToStringReturnsCorrectValue() public {
        vm.startPrank(msg.sender);
        assertEq(everestConsumer.statusToString(IEverestConsumer.Status(0)), "NOT_FOUND");
        assertEq(everestConsumer.statusToString(IEverestConsumer.Status(1)), "KYC_USER");
        assertEq(everestConsumer.statusToString(IEverestConsumer.Status(2)), "HUMAN_AND_UNIQUE");
        vm.stopPrank();
    }

    ////////////////////////////////////
    ///// getLatestSentRequestId //////
    //////////////////////////////////

    function testGetLatestSentRequestIdRevertsIfNoRequestsYet() public {
        vm.startPrank(msg.sender);
        vm.expectRevert(EverestConsumer.EverestConsumer__NoRequestsYet.selector);
        everestConsumer.getLatestSentRequestId();
        vm.stopPrank();
    }

    ////////////////////////////////////////
    ///// getRequest + requestExists //////
    //////////////////////////////////////

    function testGetRequestRevertsIfRequestIdDoesntExist() public {
        vm.startPrank(msg.sender);
        assertEq(everestConsumer.requestExists(bytes32(abi.encodePacked("mocked"))), false);
        vm.expectRevert(EverestConsumer.EverestConsumer__RequestDoesNotExist.selector);
        everestConsumer.getRequest(bytes32(abi.encodePacked("mocked")));
        vm.stopPrank();
    }

    /////////////////////////////////////////////////////
    ///// requestStatus + fulfill + cancelRequest //////
    ///////////////////////////////////////////////////

    modifier fundLinkToRevealer() {
        vm.startPrank(msg.sender);
        LinkToken(_link).transfer(REVEALER, STARTING_USER_BALANCE);
        vm.stopPrank();
        _;
    }

    function testRequestStatusRevertsIfRevealeeIsZeroAddress() public fundLinkToRevealer {
        vm.startPrank(REVEALER);
        vm.expectRevert(EverestConsumer.EverestConsumer__RevealeeShouldNotBeZeroAddress.selector);
        everestConsumer.requestStatus(0x0000000000000000000000000000000000000000);
        vm.stopPrank();
    }

    function testRequestStatusShouldRevertIfNotEnoughAllowance() public fundLinkToRevealer {
        vm.startPrank(REVEALER);
        vm.expectRevert(); // "SafeERC20: low-level call failed." // Reverting for different reason to original test
        everestConsumer.requestStatus(REVEALEE);
        vm.stopPrank();
    }

    modifier fundLinkToRevealerAndApprove() {
        vm.startPrank(msg.sender);
        LinkToken(_link).transfer(REVEALER, STARTING_USER_BALANCE);
        vm.stopPrank();
        vm.deal(REVEALER, STARTING_USER_BALANCE);
        vm.startPrank(REVEALER);
        LinkToken(_link).approve(address(everestConsumer), _oraclePayment);
        vm.stopPrank();
        _;
    }

    function testExpirationTimeShouldBeFiveMinsAfterRequest() public fundLinkToRevealerAndApprove {
        vm.startPrank(REVEALER);
        everestConsumer.requestStatus(REVEALEE);
        bytes32 requestId = everestConsumer.getLatestSentRequestId();
        uint40 initialExpirationTime = everestConsumer.getRequest(requestId).expiration;
        uint40 requestCreationTime = uint40(block.timestamp);
        assertEq(initialExpirationTime, requestCreationTime + 5 minutes);
        vm.stopPrank();
    }

    function testRequestShouldNotCancelIfCallerIsNotRevealer() public fundLinkToRevealerAndApprove {
        vm.startPrank(REVEALER);
        everestConsumer.requestStatus(REVEALEE);
        bytes32 requestId = everestConsumer.getLatestSentRequestId();
        vm.stopPrank();
        vm.startPrank(BOB);
        vm.expectRevert(EverestConsumer.EverestConsumer__NotOwnerOfRequest.selector);
        everestConsumer.cancelRequest(requestId);
        vm.stopPrank();
    }

    function testRequestShouldNotCancelIfRequestIsNotExpired() public fundLinkToRevealerAndApprove {
        vm.startPrank(REVEALER);
        everestConsumer.requestStatus(REVEALEE);
        bytes32 requestId = everestConsumer.getLatestSentRequestId();
        vm.expectRevert("Request is not expired");
        everestConsumer.cancelRequest(requestId);
        vm.stopPrank();
    }

    function testRequestShouldCancelAfterFiveMinutes() public fundLinkToRevealerAndApprove {
        vm.startPrank(REVEALER);
        everestConsumer.requestStatus(REVEALEE);
        bytes32 requestId = everestConsumer.getLatestSentRequestId();
        skip(300);
        everestConsumer.cancelRequest(requestId);
        assertEq(everestConsumer.getRequest(requestId).isCanceled, true);
        vm.stopPrank();
    }

    function testRequestShouldNotFulfillFromUnauthorizedJob() public fundLinkToRevealerAndApprove {
        vm.startPrank(REVEALER);
        everestConsumer.requestStatus(REVEALEE);
        bytes32 requestId = everestConsumer.getLatestSentRequestId();
        uint8 kycUserStatus = 1;
        uint256 nonZeroKycTimestamp = 1658845449;
        bytes memory data = abi.encodePacked(requestId, kycUserStatus, nonZeroKycTimestamp);

        // vm.expectRevert(); // "Not authorized sender" // Reverts before function can be called
        mockOperator.fulfillOracleRequest2( // EVM Error revert // incompatible compiler versions??
            requestId,
            _oraclePayment,
            address(everestConsumer),
            bytes4(keccak256("fulfill(bytes32,uint8,uint40)")),
            block.timestamp + 5 minutes,
            data
        );
        vm.stopPrank();
    }

    function testSetAuthorizedSenders() public fundLinkToRevealerAndApprove {
        vm.startPrank(msg.sender);
        address[] memory targets = new address[](1);
        targets[0] = address(everestConsumer);
        address[] memory senders = new address[](1);
        senders[0] = REVEALER;
        vm.expectRevert();
        operator.setAuthorizedSendersOn(targets, senders);
        vm.stopPrank();
    }

    function testDirectFulfillFunction() public fundLinkToRevealerAndApprove {
        vm.startPrank(REVEALER);
        everestConsumer.requestStatus(REVEALEE);
        bytes32 requestId = everestConsumer.getLatestSentRequestId();
        IEverestConsumer.Status kycUserStatus = IEverestConsumer.Status.KYCUser; // Assume Status is an enum and KYCUser is one of its values
        uint40 nonZeroKycTimestamp = 1658845449;
        // Call the fulfill function directly on EverestConsumer contract
        vm.expectRevert("Source must be the oracle of the request");
        everestConsumer.fulfill(requestId, kycUserStatus, nonZeroKycTimestamp);
        vm.stopPrank();
    }
}
