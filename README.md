# forge-deploy-lite

DeployLite is a forge script to help deployment of contracts with forge and register deployed addresses in a json file

## setup

- [install forge](https://book.getfoundry.sh/getting-started/installation)
- install forge-deploy-lite to your project, with  :
    `forge install zapaz/forge-deploy-lite`
- initialize `addresses.json` file for the target network with :

```json
{
  "<chain-id>": {
    "chainName": "<chain-name>"
  }
}
```

example :

```json
{
  "1": {
    "chainName": "mainnet"
  },
  "11155111": {
    "chainName": "sepolia"
  }
}
```


#### OPTIONAL
- `chainName` field is optional, but convenient for human readibility
- whatever fields can also be added  manually in `addresses.json`

## howto

#### write your deploy script :

The `Counter` deploy script is as follow, to be writen in a file `DeployCounter.s.sol` :

```solidity
import {DeployLite} from "script/DeployLite.sol";
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

#### simulate contract deployment :

To simulate deployment of your contract, launch the following command:

```bash
forge script script/DeployCounter.s.sol --rpc-url sepolia
```


#### deploy contract :

To deploy and verify your contract, launch the following command:

```bash
forge script script/DeployCounter.s.sol --rpc-url sepolia --broadcast --verify  --<wallet params>
```

#### read deployed addresses :

```bash
cat addresses.json
```

#### redeploy same contract

By default will not redeploy if bytecode is already deployed.

But if you have to redeploy contract with same bytecode, but different params, just delete the address manually from `adresses.json` (or move it to some `Counter.old.1` field, to keep history of all addresses)

Add `bytecode_hash = "none"` in your `foundry.toml` file, otherwise you will get metadata hash at the end of your deployed code, making it undeterministic: i.e. will change every time you change a comment

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

## todo
- support immutable variables
- manage deployment failure... i.e. not writing addresses in this case
- manage zkSync Era specific deployment
- ...

Any suggestions welcome! (just open an issue or a PR)

## aknowledgement

- inspired by @wighawag great [hardhat-deploy](https://github.com/wighawag/hardhat-deploy)
- a brand new forge version [forge-deploy](https://github.com/wighawag/forge-deploy) also available with full deploy functionnalies
