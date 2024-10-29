// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SupplyChainContract {
    struct Supply {
        uint256 id;
        uint256 price; // Price in Wei
        bool is_received;
        bool is_loaded;
        bool is_shipped;
        bool is_delivered;
        bool is_paid;
    }

    event SupplyAdded(address indexed adder, uint256 indexed id);
    event Received(address indexed owner, uint256 indexed id);
    event Loaded(address indexed owner, uint256 indexed id);
    event Shipped(address indexed owner, uint256 indexed id);
    event Delivered(address indexed owner, uint256 indexed id);
    event PaymentForwarded(address indexed owner, uint256 indexed amount);
    event Paid(address indexed owner, uint256 indexed id, uint256 indexed amount);

    event FallbackCalled(address sender, bytes data);

    Supply[] supplies;
    address owner;
    address payable owner_wallet;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract deployer is allowed to do this !");
        _;
    }

    function setOwnerWallet(address payable wallet) public onlyOwner {
        owner_wallet = wallet;
    }

    function getOwnerWallet() public view returns (address payable wallet) {
        return owner_wallet;
    }

    function addSupply(uint256 id, uint256 price) public {
        require(price > 0, "Price must be greater than zero.");
        
        for (uint256 i = 0; i < supplies.length; i++) {
            require(supplies[i].id != id, "Supply with this ID already exists!");
        }
        
        supplies.push(Supply(id, price, false, false, false, false, false));
        emit SupplyAdded(msg.sender, id);
    }

    function receiveSupply(uint256 id) public onlyOwner {
        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                supplies[i].is_received = true;

                emit Received(msg.sender, id);

                break;
            }
        }
    }

    function forwardPayment(uint256 amount) private onlyOwner {
        require(amount > 0, "No funds to forward");
        (bool success, ) = owner_wallet.call{value: amount}("");

        require(success, "Transfer failed");
        emit PaymentForwarded(owner_wallet, amount);
    }

    function paySupply(uint256 id) public payable {
        require(msg.value > 0, "Send some Ether to pay for the supply");

        uint256 price;

        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                price = supplies[i].price;

                break;
            }
        }
        
        require(msg.value == price, "Incorrect payment amount");

        forwardPayment(msg.value);
        
        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                supplies[i].is_paid = true;
                break;
            }
        }

        emit Paid(msg.sender, id, msg.value);
    }

    function loadSupply(uint256 id) public onlyOwner {
        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                supplies[i].is_loaded = true;

                emit Loaded(msg.sender, id);

                break;
            }
        }
    }

    function shipSupply(uint256 id) public onlyOwner {
        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                supplies[i].is_shipped = true;

                emit Shipped(msg.sender, id);

                break;
            }
        }
    }

    function deliveredSupply(uint256 id) public onlyOwner {
        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                supplies[i].is_delivered = true;

                emit Delivered(msg.sender, id);

                break;
            }
        }
    }

    function seeSupply() public view returns (Supply[] memory) {
        return supplies;
    }

    function seeSupply(uint256 id) public view returns (Supply memory) {
        for (uint256 i = 0; i < supplies.length; i++) {
            if (supplies[i].id == id) {
                return supplies[i];
            }
        }
        revert("Supply not found");
    }

    fallback() external payable {
        emit FallbackCalled(msg.sender, msg.data);
    }

    receive() external payable {
        emit FallbackCalled(msg.sender, "");
    }
}