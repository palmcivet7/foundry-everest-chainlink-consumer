// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "../../src/interfaces/IEverestConsumer.sol";

contract MockOperator {
    address public consumerAddress;
    mapping(bytes32 => bool) public processedRequests;
    bytes32 public currentRequestId; // To simulate the requestId returned by operatorRequest

    // Assuming you have a struct for storing request data
    struct Request {
        address sender;
        uint256 payment;
        bytes data;
    }

    // For testing, you can have a mapping that allows you to retrieve request data using a request ID
    mapping(bytes32 => Request) public requests;

    constructor(address _consumerAddress) {
        consumerAddress = _consumerAddress;
    }

    function onTokenTransfer(address _sender, uint256 _payment, bytes calldata _data) external returns (bool) {
        // Decode the data if necessary.
        // Here, we'll just create a request ID from the sender and current block timestamp.
        bytes32 requestId = keccak256(abi.encodePacked(_sender, block.timestamp));

        // Store the request data in the mapping
        requests[requestId] = Request({sender: _sender, payment: _payment, data: _data});

        // Emit an event if necessary, for easier tracking in the logs
        emit RequestReceived(requestId, _sender, _payment, _data);

        return true;
    }

    event RequestReceived(bytes32 indexed requestId, address indexed sender, uint256 payment, bytes data);

    // Simulate operatorRequest function
    function operatorRequest(bytes32, /*_jobId*/ bytes4 _callbackFunctionId, bytes calldata _data)
        external
        returns (bytes32 requestId)
    {
        require(consumerAddress != address(0), "MockOperator: Invalid consumer address");

        // Let's create a fake requestId for testing purposes.
        // Here, we're simply using a keccak256 hash for simulation.
        currentRequestId = keccak256(abi.encodePacked(block.timestamp, _callbackFunctionId, _data));

        return currentRequestId;
    }

    // Simulate a Chainlink response
    function simulateChainlinkResponse(IEverestConsumer.Status _status, uint40 _kycTimestamp) external {
        require(!processedRequests[currentRequestId], "MockOperator: Request already processed");
        require(currentRequestId != bytes32(0), "MockOperator: No current request set");

        processedRequests[currentRequestId] = true;

        // Calling the EverestConsumer's fulfill function directly
        IEverestConsumer(consumerAddress).fulfill(currentRequestId, _status, _kycTimestamp);
    }
}
