# forge-deploy-lite

DeployLite is a forge script to ease contract deployments on mutliple EVM networks

DeployLite registers deployed addresses in a single json file, to be used by your frontend UI

## features
- **Idempotent Deployments**: DeployLite ensures that a contract is deployed only if it is not already deployed onchain
- **Immutable Variable Handling**: DeployLite identifies contracts by their on-chain bytecode, even when immutable variables are present
- **Metadata Management**: DeployLite avoids redeploying contracts if only metadata (such as formatting or comments) has changed, without any code modifications
- **Multi-Contract Support**: DeployLite supports the deployment of multiple contracts in a single operation

You can use a unique `DeployAll.s.sol` script to deploy all your contracts, ensuring only modified contracts to be redeployed.

## setup

### install

install `forge-deploy-lite` into your foundry project with:

```sh
forge install zapaz/forge-deploy-lite
```

### configuration

Set specific `fs_permissions` settings in your `foundry.toml` configuration, like this:

```toml
# to write to addresses.json
fs_permissions = [
  {  access = "read-write", path = "./addresses.json"},
  {  access = "read-write", path = "./out"}]
```

### environment
Set environment variables, to be used in `foundry.toml`
- INFURA_API_KEY (or ALCHEMY_API_KEY or other...) for your rpc url
- ETHERSCAN_API_KEY_ETHEREUM (or other...) to verify your contract

to be used by `deploy scripts`:
- CHAIN is the name of the chain you are deploying to
- SENDER the address of this sender of the deployment transactions
- ACCOUNT is the name of one keystore account holding securely the private key of SENDER


Here is an [example `.env`](.env.anvil) file for testing with anvil:

```bash
export INFURA_API_KEY="xxxxxxxxxxxxx"
export ETHERSCAN_API_KEY_ETHEREUM="xxxxxxxxxxxxx"

export CHAIN="anvil"
export SENDER="0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
export ACCOUNT="anvil5"
```

### deployLite script

To keep it simple, only use `deployLite` for your deployment script.

The `Counter` deploy script is as follow, to be writen in a file `DeployCounter.s.sol` :

`script/DeployCounter.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DeployLite} from "lib/forge-deploy-lite/DeployLite.s.sol";
import {Counter} from "src/examples/Counter.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address) {
        return deployLite("Counter", abi.encode(42));
    }

    function run() public virtual {
        deployCounter();
    }
}
```

For your contract, just replace everywhere `Counter` by the name of your contract.

DeployLite checks onchain if bytecode is already deployed, and then stops if this is the case, or deploys contract and writes deployed address in `adresses.json`
(you have to pass the forge script 2 times to validate that a deployment has succeeded, if not some "Contract_last" addresses will appears in your `addresses.json` file)

`deployLite` comes in 2 flavors to optionnaly handle constructor argument

- one param when you have no constructor arguments
```solidity
function deployLite(string memory name) external returns (address addr);
```
- two params when you have constructor arguments
```solidity
function deployLite(string memory name, bytes memory data) external returns (address addr);
```
### advanced deploy script

Two more advanced deploy functions are avaible, to tune the deployment process:  `deployState`and `deploy`functions

- `deployState` return the actual state of deployment (must be outside `broadcasting`)
  - possible values are :
    - Null: deployment not checked yet
    - None: no deployment found
    - New: new deployment has just been made
    - Already: existing identic deployment exists, no need to redeploy
    - Older: a older different deployment exists, redeploy needed
```solidity
function deployState(string memory name) public returns (DeployState state)
```
- `deploy` actually deploys data bytecode for named contract (must be inside `broadcasting`)
```solidity
function deploy(string memory name, bytes memory data) external returns (address addr);
```

Here is an example for `Complex.sol` contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {DeployLite} from "../../src/DeployLite.s.sol";
import {Complex} from "../../src/examples/Complex.sol";

contract DeployComplex is DeployLite {
    function deployComplex() public returns (address) {
        bytes memory args = abi.encode(1_000, 1);

        DeployState state = deployState("Complex", args);

        if (state == DeployState.None || state == DeployState.Older) {
            vm.broadcast();
            deploy("Complex", args);
        }
        return readAddress("Complex");
    }

    function run() public virtual {
        deployComplex();
    }
}

```

## deployement


#### deploy contract

To deploy and verify your contract, launch the following command:

```bash
forge script script/deploy/DeployCounter.s.sol --fork-url $CHAIN --sender $SENDER --account $ACCOUNT --broadcast --verify
```
or via pnpm task
```bash
pnpm deploy:broadcast --verify
```

#### validate contract deployment

To validate deployment of your contract, launch the following command:

```bash
forge script script/deploy/DeployCounter.s.sol --fork-url $CHAIN --sender $SENDER
```
or via pnpm task
```bash
pnpm deploy:validate
```


#### deploy and validate contract
To deploy AND validate your contract, launch the following command:

```bash
pnpm deploy:deploy
```
It will run `deploy:broadcast` then `deploy:validate`


#### multiple contracts deployment

You can deploy multiple contracts at the same time, in the same block

Just write a `Deploy<Contract>.s.sol` for each contract and a `DeployAll.s.sol` script with `run` inluding multiple `deploy("CONTRA${CT_NAME}")`calls like this :

```solidity
contract DeployAll is Contract, Contract2{
    function run() public override(Contract, Contract2)
    {
        deployContract();
        deployContract2();
    }
}
```

It is recommended to deploy contracts one by one the first time, then you can use `DeployAll` (with same compiler options), as it will only redeploy modified contracts.

## addresses.json

here is a example of the resulting file:

`addresses.json`

```json
{
  "31337": {
    "chainName": "local",
    "Counter": "0x90193C961A926261B756D1E5bb255e67ff9498A1"
  },
  "11155111": {
    "chainName": "sepolia",
    "Counter": "0x34A1D3fff3958843C43aD80F30b94c510645C316"
  }
}
```

Note that you can get some fields like:
```json
"Counter_last": "0x34A1D3fff3958843C43aD80F30b94c510645C316"`
```

In this case, run the validate script to get a validation (`pnpm deploy:validate`) of this deployement.
Sometimes deployments fails and this `..._last` address is not deployed, in this case just relaunch deploy script (`pnpm deploy:broadcast`). No worry to delete this field.

## todo
- document howto to also include deploy in tests
- manage zkSync Era specific deployment
- ...

Any suggestions welcome! (just open an issue or a PR)

## aknowledgement

- inspired by [@wighawag](https://github.com/wighawag) great [hardhat-deploy](https://github.com/wighawag/hardhat-deploy)
- a forge version by [@wighawag](https://github.com/wighawag) also available [forge-deploy](https://github.com/wighawag/forge-deploy)  with full deploy functionnalies
