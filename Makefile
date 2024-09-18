-include .env

.PHONY: all test deploy

build :; forge build 

test :; forge test

install :; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

deploy-sepolia:
	@forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --account mine --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

forge-verify:
	@forge verify-contract 0xb8D7d386035e62F8F9fe0DA45783fFe9C75b7877 src/Raffle.sol:Raffle --etherscan-api-key $(ETHERSCAN_API_KEY) --rpc-url $(SEPOLIA_RPC_URL) --show-standard-json-input > json.json

