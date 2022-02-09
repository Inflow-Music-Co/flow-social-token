all: storyline
.PHONY: storyline
story: 
	go run ./tasks/user_story/main.go

.PHONY: event
event:
	go run ./event/main.go

#this goal mints new flow tokens on emulator takes an account(Addres) env and can take an amount(int:100) env
.PHONY:mint-quote
mint-quote:
	go run ./tasks/get_mint_quote/main.go

.PHONY: mint-fusd
mint-fusd:
	go run ./tasks/mint_fusd/main.go

.PHONY: mint-with-collateral
mint-with-collateral:
	go run ./tasks/mint_with_collateral/main.go

.PHONY: mint-with-collateral-splitter
mint-with-fee-distribution:
	go run ./tasks/mint_with_fee_distribution/main.go

.PHONY: get-social-details
get-social-details:
	go run ./tasks/get_social_details/main.go

.PHONY: register-tokens
register-token:
	go run ./tasks/register_token/main.go

.PHONY: mint-burn-instant
mint-burn-instant:
	go run ./tasks/mint_burn_instant/main.go

.PHONY: transfer-token-different-vaults
transfer-token-different-vaults-negative:
	go run ./tasks/transfer_token_different_vaults_negative/main.go

.PHONY: transfer-token-same-vaults
transfer-token-same-vaults:
	go run ./tasks/transfer_token_same_vaults/main.go

.PHONY: mint-total-supply
mint-total-supply:
	go run ./tasks/mint_total_supply/main.go

.PHONY: mint-burn-100-tokens
mint-burn-100-tokens:
	go run ./tasks/mint_burn_100_tokens/main.go
.PHONY: get_mint_quote_loop
get-mint-quote-loop:
	go run ./tasks/get_mint_quote_loop/main.go

.PHONY: minting_in_loop
mint-loop:
	go run ./tasks/minting_in_loop/main.go

.PHONY: minting_in_loop
burn-loop:
	go run ./tasks/burning_in_loop/main.go

.PHONY: burning_in_loop
single-mint-burn:
	go run ./tasks/single_mint_burn/main.go

.PHONY: single_mint_burn
mint-1000-burn-100-tokens:
	go run ./tasks/mint_1000_burn_100_tokens/main.go

.PHONY: mint_1000_burn_100_tokens
mint-2000-burn-1300_tokens:
	go run ./tasks/mint_2000_burn_1300_tokens/main.go

.PHONY: mint_2000_burn_1300_tokens
mint-5000-burn-3500-tokens:
	go run ./tasks/mint_5000_burn_3500_tokens/main.go
.PHONY: mint_5000_burn_3500_tokens
