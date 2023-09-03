# forge-deploy-lite

DeployLite is a forge script to help contract deployments on mutliple evm networks

DeployLite registers deployed addresses in a single json file, to be used by your frontend UI

## setup

### install
install `forge-deploy-lite` into your foundry project with:

```sh
forge install zapaz/forge-deploy-lite
```

### configuration
setup your foundry configuration, with specific `fs_permissions` and `bytecode_hash` settings,
here is an example:

`foundry.toml`
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

# to write to addresses.json
fs_permissions = [
  {  access = "read-write", path = "./addresses.json"},
  {  access = "read-write", path = "./out"}]
# to get deterministic deployed code
bytecode_hash = "none"

[rpc_endpoints]
sepolia = "https://rpc.ankr.com/eth_sepolia"
```


#### script

The `Counter` deploy script is as follow, to be writen in a file `DeployCounter.s.sol` :

`script/DeployCounter.s.sol`
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DeployLite} from "lib/forge-deploy-lite/script/DeployLite.sol";
import {Counter} from "src/Counter.sol";

contract DeployCounter is DeployLite {
    function deployCounter() public returns (address counter) {
        vm.startBroadcast();

        counter = address(new Counter());

        // ...
        // put here additional code to intialize your deployed contract
        // warning : use deployer instead of `msg.sender`
        // ...

        vm.stopBroadcast();
    }

    function run() public virtual {
        deploy("Counter");
    }
}
```

For your contract, just replace everywhere `Counter` by the name of your contract (in imports, text field, and function/contracts/file names).

DeployLite checks onchain if bytecode is already deployed, and then stops if this is the case, or deploys contract and writes deployed address in `adresses.json`

DeployLite links `deploy("Counter")` to `deployCounter` via a low level `call` that changes `msg.sender` (to the deploy script address), so use `deployer` instead (similar reason to OZ `_msgSender()`)

## deploy

#### simulate contract deployment

To simulate deployment of your contract, launch the following command:

```bash
forge script script/DeployCounter.s.sol --rpc-url sepolia
```

#### deploy contract

To deploy and verify your contract, launch the following command:

```bash
forge script script/DeployCounter.s.sol --rpc-url sepolia --broadcast --verify  --<wallet params>
```

#### redeploy same contract

By default will not redeploy if bytecode is already deployed.

But if you have to redeploy contract with same bytecode, but different params, just delete the address manually from `adresses.json` (or move it to some `Counter.old.1` field, to keep history of all addresses)

#### deploy multiple contracts

You can deploy multiple contracts at the same time, in the same block !

Just write a `Deploy<Contract>.s.sol` for each contract and a `DeployAll.s.sol` script with `run` inluding multiple `deploy("CONTRA${CT_NAME}")`calls like this :

```solidity
contract DeployAll is Contract, Contract2{
    function run() public override(Contract, Contract2)
    {
        deploy("Contract");
        deploy("Contract2");
    }
}
```

It is recommended to deploy contracts one by one the first time, then you can use `DeployAll` (with same compiler options), as it will only change modified contracts.

## addresses.json

#### read deployed addresses

```bash
cat addresses.json
```

#### example

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

## todo
- support immutable variables
- manage deployment failure... i.e. not writing addresses in this case
- manage zkSync Era specific deployment
- ...

Any suggestions welcome! (just open an issue or a PR)

## aknowledgement

- inspired by @wighawag great [hardhat-deploy](https://github.com/wighawag/hardhat-deploy)
- a brand new forge version [forge-deploy](https://github.com/wighawag/forge-deploy) also available with full deploy functionnalies
