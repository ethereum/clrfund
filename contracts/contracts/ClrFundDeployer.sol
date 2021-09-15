/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

pragma solidity ^0.6.12;
import './MACIFactory.sol';
import './ClrFund.sol';
import './recipientRegistry/OptimisticRecipientRegistry.sol';
import './userRegistry/BrightIdUserRegistry.sol';

contract CloneFactory { // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

contract ClrFundDeployer is CloneFactory { 
    
    address public template;
    mapping (address => bool) public clrfunds;
    mapping (address => bool) public recipientRegistries;
    mapping (address => bool) public userRegistries;
    
    uint clrId = 0;
    uint recipientRegistryId = 0;
    uint userId = 0;

    ClrFund private clrfund; // funding factory contract
    OptimisticRecipientRegistry private recipientRegistry; // recipient registry contract
    BrightIdUserRegistry private userRegistry; // user registry contract

    constructor(address _template) public {
        template = _template;
    }
    
    event NewInstance(address indexed clrfund);
    event RegisterFund(address indexed clrfund, string metadata);
    event RegisterOptimisticRecipientRegistry(address indexed recipientRegistry, string metadata);
    event RegisterBrightIdUserRegistry(address indexed userRegistry, string metadata);

    function deployFund(
      MACIFactory _maciFactory
    ) public returns (address) {
        ClrFund clrfund = ClrFund(createClone(template));
        
        clrfund.init(
            _maciFactory
        );
       
        emit NewInstance(address(clrfund));
        
        return address(clrfund);
    }
    
    function registerFundInstance(
        address _clrFundAddress,
        string memory _metadata
      ) public returns (bool) {
          
      clrfund = ClrFund(_clrFundAddress);
      
      require(clrfunds[_clrFundAddress] == false, 'ClrFund: metadata already registered');

      clrfunds[_clrFundAddress] = true;
      
      clrId = clrId + 1;
      emit RegisterFund(_clrFundAddress, _metadata);
      return true;
      
    }
    
    function registerRecipientRegistryInstance(
        address _recipientRegistryAddress,
        string memory _metadata
      ) public returns (bool) {
          
      recipientRegistry = OptimisticRecipientRegistry(_recipientRegistryAddress);
      
      require(recipientRegistries[_recipientRegistryAddress] == false, 'RecipientRegistry: metadata already registered');

      recipientRegistries[_recipientRegistryAddress] = true;
      
      recipientRegistryId = recipientRegistryId + 1;
      emit RegisterOptimisticRecipientRegistry(_recipientRegistryAddress, _metadata);
      return true;
      
    }
    
    function registerUserRegistryInstance(
        address _userRegistryAddress,
        string memory _metadata
      ) public returns (bool) {
          
      userRegistry = BrightIdUserRegistry(_userRegistryAddress);
      
      require(userRegistries[_userRegistryAddress] == false, 'UserRegistry: metadata already registered');

      userRegistries[_userRegistryAddress] = true;
      
      userId = userId + 1;
      emit RegisterBrightIdUserRegistry(_userRegistryAddress, _metadata);
      return true;
      
    }
    
}