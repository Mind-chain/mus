// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MindUsernameSystem is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public registrationFee = 1 ether;
    uint256 private totalFees;

    mapping(string => address) private usernameToAddress;
    mapping(address => string) private addressToUsername;
    mapping(string => bool) private bannedUsernames;

    address private admin; 

    event UsernameRegistered(address indexed userAddress, string username, uint256 feePaid);
    event SentToUser(address indexed sender, string receiverUsername, uint256 amount);
    event FeesWithdrawn(address indexed admin, uint256 amount);
    event UsernameBanned(string username);
    event UsernameUnbanned(string username);
    event UsernameUpdated(address indexed userAddress, string oldUsername, string newUsername);
    event RegistrationFeeAdjusted(uint256 oldFee, uint256 newFee);

    constructor() Ownable(msg.sender) {
        _setAdmin(msg.sender);
    }

    function _setAdmin(address newAdmin) internal {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }

function registerUsername(string memory username) external payable nonReentrant {
    require(bytes(username).length > 0, "Username cannot be empty");
    require(!bannedUsernames[username], "Username is banned");
    require(usernameToAddress[username] == address(0), "Username already taken");
    require(bytes(addressToUsername[msg.sender]).length == 0, "Address already has a username");
    require(msg.value == registrationFee, "Incorrect registration fee amount");

    totalFees = totalFees.add(msg.value);
    usernameToAddress[username] = msg.sender;
    addressToUsername[msg.sender] = username;

    emit UsernameRegistered(msg.sender, username, msg.value);
}


    function getUsername(address userAddress) external view returns (string memory) {
        return addressToUsername[userAddress];
    }

    function getAddress(string memory username) external view returns (address) {
        return usernameToAddress[username];
    }

    function sendToUser(string memory receiverUsername) external payable nonReentrant {
        address receiverAddress = usernameToAddress[receiverUsername];
        require(receiverAddress != address(0), "Receiver username not found");

        (bool sent, ) = payable(receiverAddress).call{value: msg.value}("");
        require(sent, "Failed to send Ether to receiver");

        emit SentToUser(msg.sender, receiverUsername, msg.value);
    }

    function withdrawFees() external onlyOwner nonReentrant {
        require(totalFees > 0, "No fees to withdraw");

        (bool sent, ) = payable(admin).call{value: totalFees}("");
        require(sent, "Failed to withdraw fees");

        emit FeesWithdrawn(admin, totalFees);
        totalFees = 0;
    }

    function setRegistrationFee(uint256 newFee) external onlyOwner nonReentrant {
        require(newFee > 0, "Registration fee must be greater than zero");
        emit RegistrationFeeAdjusted(registrationFee, newFee);
        registrationFee = newFee;
    }

    function banUsername(string memory username) external onlyOwner nonReentrant {
        require(bytes(username).length > 0, "Username cannot be empty");
        bannedUsernames[username] = true;

        emit UsernameBanned(username);
    }

    function unbanUsername(string memory username) external onlyOwner nonReentrant {
        require(bytes(username).length > 0, "Username cannot be empty");
        bannedUsernames[username] = false;

        emit UsernameUnbanned(username);
    }

    function updateUsername(string memory newUsername) external nonReentrant {
        require(bytes(newUsername).length > 0, "New username cannot be empty");
        require(usernameToAddress[newUsername] == address(0), "New username already taken");
        require(!bannedUsernames[newUsername], "New username is banned");

        string memory oldUsername = addressToUsername[msg.sender];
        require(bytes(oldUsername).length > 0, "No existing username for the sender");

        usernameToAddress[oldUsername] = address(0);
        usernameToAddress[newUsername] = msg.sender;
        addressToUsername[msg.sender] = newUsername;

        emit UsernameUpdated(msg.sender, oldUsername, newUsername);
    }

  
    receive() external payable {
        revert("This contract does not accept Ether directly");
    }
}
