all: clean  format build test deploy

clean:
	forge clean

format:
	forge fmt

check: install-solhint
	solhint src/**/*.sol

build: format
	forge build

test:
	forge test

deploy:
	forge script script/DeployCounter.s.sol

deploy-anvil:
	@forge script script/DeployCounter.s.sol --rpc-url anvil --broadcast --sender $(ANVIL_ETH_FROM) --private-key $(ANVIL_PRIVATE_KEY)

install-solhint:
	@command -v solhint >/dev/null 2>&1 || (echo "solhint not found, installing..."; pnpm install -g solhint)

