pragma solidity >=0.5.0 <0.8.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

// Proxy contract for testing throws
contract ThrowProxy {
  SupplyChain public target;

  constructor(SupplyChain _target) public {
    target = _target;
  }

  function() external payable {
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
      (bool success, ) = address(target).call(abi.encodeWithSignature("addItem(string,uint256)", _name, _price));
      return success;
  }

  function buyItem(uint _sku, uint _offer) public returns (bool) {
      (bool success, ) = address(target).call.value(_offer)(abi.encodeWithSignature("buyItem(uint256)", _sku));
      return success;
  }
  function shipItem(uint _sku) public returns (bool) {
      (bool success, ) = address(target).call(abi.encodeWithSignature("shipItem(uint256)", _sku));
      return success;
  }
  function receiveItem(uint _sku) public returns (bool) {
      (bool success, ) = address(target).call(abi.encodeWithSignature("receiveItem(uint256)", _sku));
      return success;
  }
}

contract TestSupplyChain {
    // Truffle will send the TestContract one Ether after deploying the contract.
    uint public initialBalance = 50 ether;
    SupplyChain supplyChain;
    ThrowProxy user1;
    ThrowProxy user2;
    ThrowProxy user3;

    function beforeEach() public {
    supplyChain = new SupplyChain();
    user1 = new ThrowProxy(supplyChain);
    user2 = new ThrowProxy(supplyChain);
    user3 = new ThrowProxy(supplyChain);
    address(user1).transfer(1 ether);
    address(user2).transfer(1 ether);
    address(user3).transfer(1 ether);
  }


  function() external payable { }

    // Test for failing conditions in this contracts:
    // https://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests

    // buyItem

    // test for failure if user does not send enough funds
    function testFailureUserNotEnoughFunds() public {
        Assert.isTrue(user1.addItem("item 1", 1000 ether), "should add item");

        Assert.isFalse(user2.buyItem(0, 0.2 ether), "should not buy with less money than price");
    }
    // test for purchasing an item that is not for Sale
    function testPurchasingItemNotForSale() public {
        Assert.isTrue(user1.addItem("item 1", 0.1 ether), "should add item");

        Assert.isTrue(user2.buyItem(0, 0.2 ether), "should buy");

        Assert.isFalse(user3.buyItem(0, 0.2 ether), "should not buy item already sold");

        Assert.isFalse(user3.buyItem(1, 0.2 ether), "should not buy nonexisting item");
    }


    // shipItem

    // test for calls that are made by not the seller
    function testCallsMadeNotBySeller() public {
        Assert.isTrue(user1.addItem("item 1", 0.1 ether), "should add item");

        Assert.isTrue(user2.buyItem(0, 0.2 ether), "should buy");

        Assert.isFalse(user2.shipItem(0), "only made by seller");
        Assert.isFalse(user3.shipItem(0), "only made by seller");
        Assert.isTrue(user1.shipItem(0), "should be made by seller");
    }
    // test for trying to ship an item that is not marked Sold
    function testShipUnsold() public {
        Assert.isTrue(user1.addItem("item 1", 0.1 ether), "should add item");

        Assert.isFalse(user1.shipItem(0), "should not ship unsold item");
    }

    // receiveItem

    // test calling the function from an address that is not the buyer
    function testReceiveItemNotBuyer() public {
        Assert.isTrue(user1.addItem("item 1", 0.1 ether), "should add item");

        Assert.isTrue(user2.buyItem(0, 0.2 ether), "should buy");

        Assert.isTrue(user1.shipItem(0), "should be made by seller");

        Assert.isFalse(user3.receiveItem(0), "cannot receive item");
        Assert.isFalse(user1.receiveItem(0), "cannot receive item");
        Assert.isTrue(user2.receiveItem(0), "should receive item");
    }
    // test calling the function on an item not marked Shipped
    function testReceiveItemNotShipped() public {
        Assert.isTrue(user1.addItem("item 1", 0.1 ether), "should add item");

        Assert.isTrue(user2.buyItem(0, 0.2 ether), "should buy");

        Assert.isFalse(user2.receiveItem(0), "cannot receive unshipped item");
    }

}
