// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../../src/interfaces/IEverestConsumer.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol"; // import for LINK token

contract MockOperator {
    address public consumerAddress;
    LinkTokenInterface public linkToken; // instance of the LINK token
    mapping(bytes32 => bool) public processedRequests;
    bytes32 public currentRequestId;
    bytes4 private currentCallbackFunctionId = bytes4(keccak256("fulfill(bytes32,uint8,uint40)"));
    mapping(address => bool) private s_authorizedSenders;
    address[] private s_authorizedSenderList;
    address public owner = msg.sender;

    event AuthorizedSendersChanged(address[] senders, address changedBy);

    struct Request {
        address sender;
        uint256 payment;
        bytes data;
    }

    mapping(bytes32 => Request) public requests;
    mapping(bytes32 => Commitment) public s_commitments; // mapping for commitments

    struct Commitment {
        bytes31 paramsHash;
    }

    constructor(address _linkToken) {
        linkToken = LinkTokenInterface(_linkToken);
    }

    function fulfill(bytes32 _requestId, IEverestConsumer.Status _status, uint40 _kycTimestamp) external {
        require(s_authorizedSenders[msg.sender], "Not authorized sender");

        // your fulfillment logic, probably something like:
        IEverestConsumer(consumerAddress).fulfill(_requestId, _status, _kycTimestamp);
    }

    function setConsumerAddress(address _consumerAddress) external {
        require(consumerAddress == address(0), "Consumer address already set");
        consumerAddress = _consumerAddress;
    }

    function onTokenTransfer(address _sender, uint256 _payment, bytes calldata _data) external returns (bool) {
        bytes32 requestId = keccak256(abi.encodePacked(_sender, block.timestamp));
        requests[requestId] = Request({sender: _sender, payment: _payment, data: _data});

        // This is where we'll store the commitment
        bytes31 paramsHash = _buildParamsHash(_payment, _sender, currentCallbackFunctionId, block.timestamp + 5 minutes); // just an example, set the correct callbackFunc and expiration
        s_commitments[requestId] = Commitment(paramsHash);

        emit RequestReceived(requestId, _sender, _payment, _data);
        return true;
    }

    event RequestReceived(bytes32 indexed requestId, address indexed sender, uint256 payment, bytes data);

    function operatorRequest(bytes32, bytes4 _callbackFunctionId, bytes calldata _data)
        external
        returns (bytes32 requestId)
    {
        require(consumerAddress != address(0), "MockOperator: Invalid consumer address");
        currentRequestId = keccak256(abi.encodePacked(block.timestamp, _callbackFunctionId, _data));
        return currentRequestId;
    }

    function simulateChainlinkResponse(IEverestConsumer.Status _status, uint40 _kycTimestamp) external {
        require(!processedRequests[currentRequestId], "MockOperator: Request already processed");
        require(currentRequestId != bytes32(0), "MockOperator: No current request set");

        processedRequests[currentRequestId] = true;
        IEverestConsumer(consumerAddress).fulfill(currentRequestId, _status, _kycTimestamp);
    }

    function cancelOracleRequest(bytes32 requestId, uint256 payment, bytes4 callbackFunc, uint256 expiration)
        external
    {
        bytes32 paramsHash = _buildParamsHash(payment, msg.sender, callbackFunc, expiration);
        require(s_commitments[requestId].paramsHash == paramsHash, "Params do not match request ID");
        require(expiration <= block.timestamp, "Request is not expired");

        delete s_commitments[requestId];
        emit CancelOracleRequest(requestId);

        linkToken.transfer(msg.sender, payment);
    }

    event CancelOracleRequest(bytes32 indexed requestId);

    function _buildParamsHash(uint256 _payment, address _sender, bytes4 _callbackFunctionId, uint256 _expiration)
        internal
        pure
        returns (bytes31)
    {
        return bytes31(keccak256(abi.encodePacked(_payment, _sender, _callbackFunctionId, _expiration)));
    }

    function setAuthorizedSenders(address[] calldata senders) external {
        require(senders.length > 0, "Must have at least 1 authorized sender");
        uint256 authorizedSendersLength = s_authorizedSenderList.length;
        for (uint256 i = 0; i < authorizedSendersLength; i++) {
            s_authorizedSenders[s_authorizedSenderList[i]] = false;
        }
        for (uint256 i = 0; i < senders.length; i++) {
            s_authorizedSenders[senders[i]] = true;
        }
        s_authorizedSenderList = senders;
        emit AuthorizedSendersChanged(senders, msg.sender);
    }

    function getAuthorizedSenders() external view returns (address[] memory) {
        return s_authorizedSenderList;
    }

    function isAuthorizedSender(address sender) public view returns (bool) {
        return s_authorizedSenders[sender];
    }

    function _canSetAuthorizedSenders() internal virtual returns (bool) {
        return msg.sender == owner;
    }

    function _validateIsAuthorizedSender() internal view {
        require(isAuthorizedSender(msg.sender), "Not authorized sender");
    }

    modifier validateAuthorizedSender() {
        _validateIsAuthorizedSender();
        _;
    }

    modifier validateAuthorizedSenderSetter() {
        require(_canSetAuthorizedSenders(), "Cannot set authorized senders");
        _;
    }

    event OracleResponse2(bytes32 indexed requestId);

    function fulfillOracleRequest2(
        bytes32 _requestId,
        uint256 _payment,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _expiration,
        bytes calldata _data
    ) external validateAuthorizedSender returns (bool) {
        // Step 1: Ensure that the request hasn't been fulfilled and is still valid.
        require(s_commitments[_requestId].paramsHash != bytes31(0), "Must have a valid requestId");
        bytes32 paramsHash = _buildParamsHash(_payment, _callbackAddress, _callbackFunctionId, _expiration);
        require(s_commitments[_requestId].paramsHash == paramsHash, "Params do not match request ID");
        require(_expiration > block.timestamp, "Request is expired");

        // Step 2: Decode the callback data. If your callback requires specific data decoding, do that here.
        // For the sake of this example, I will assume the callback only requires the requestId.

        // Step 3: Make the callback.
        (bool success,) = _callbackAddress.call(abi.encodeWithSelector(_callbackFunctionId, _requestId, _data));
        if (!success) {
            // If the call wasn't successful, revert the transaction.
            revert("Callback failed");
        }

        // Step 4: Remove the request's commitment to prevent any future changes/re-entrancy.
        delete s_commitments[_requestId];

        // Step 5: Emit an event.
        emit OracleResponse2(_requestId);

        return true;
    }
}
