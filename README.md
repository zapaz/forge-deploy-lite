
# forge-deploy-lite

DeployLite is a [One Script library](https://github.com/zapaz/forge-deploy-lite/blob/main/script/DeployLite.sol) to deploy contract with forge


## prerequesites
#### setup
- set INFURA_API_KEY and PRIVATE_KEY in your ENV
- initialize addresses.json file for the target network with :
```json
    {
      "<chain-id>": {
        "chainName": "<chain-name>",
        "Counter": ""
      }
    }
```
example :
```json
    {
      "1": {
        "chainName": "mainnet",
        "Counter": ""
      },
      "11155111": {
        "chainName": "sepolia",
        "Counter": ""
      }
    }
```


## howto

#### Write your deploy Counter script :

```solidity
import {DeployLite} from "script/DeployLite.sol";
import {Counter} from "src/Counter.sol";

contract DeployCounter is DeployLib {
    function deployCounter() public returns (address counter) {
        vm.startBroadcast();

        counter = address(new Counter());

        // ...
        // put here additional code to intialize your deployed contract
        // ...

        vm.stopBroadcast();
    }

    function run() public virtual {
        deploy("Counter");
    }
}

```
**Mandatory** For the deployment function of `WhateverContract` use exactly this name  : `deployWhateverContract`

On each deploy, `DeployLite` check onchain if bytecode is already deployed.

#### Deploy multiple contracts
You can deploy multiple contracts at the same time (in the same block !)
Just write a `Deploy<Contract>.s.sol` for each contract and a `DeployAll.s.sol` script with `run` inluding multiple `Deploy<Contract>`calls like this :

```solidity
contract DeployAll is Contract, Contract2{
    function run() public override(Contract, Contract2)
    {
        deploy("Contract");
        deploy("Contract2");
    }
}
```

#### To simulate deployment Counter.sol on Sepolia :

```bash
forge script script/DeployCounter.s.sol  --private-key $PRIVATE_KEY --rpc-url sepolia
```

#### To deploy Counter.sol on Sepolia :
```bash
forge script script/DeployCounter.s.sol  --private-key $PRIVATE_KEY --rpc-url sepolia --broadcast
```

#### Get back deployed addresses :

```bash
cat addresses.json
```

## aknowledgement

- Inspired by @wigawag great [hardhat-deploy](https://github.com/wighawag/hardhat-deploy)
- A brand new forge version [forge-deploy](https://github.com/wighawag/forge-deploy) also available with full functionnalies
