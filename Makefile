all: storyline
.PHONY: storyline
story: 
	go run ./Cadence/tasks/user_story/main.go

.PHONY: event
event:
	go run ./event/main.go

#this goal mints new flow tokens on emulator takes an account(Addres) env and can take an amount(int:100) env
.PHONY:mint-quote
mint-quote:
	go run ./Cadence/tasks/get_mint_quote/main.go

.PHONY: mint-fusd
mint-fusd:
	go run ./Cadence/tasks/mint_fusd/main.go

.PHONY: mint-with-collateral
mint-with-collateral:
	go run ./Cadence/tasks/mint_with_collateral/main.go

.PHONY: mint-with-collateral-splitter
mint-with-fee-distribution:
	go run ./Cadence/tasks/mint_with_fee_distribution/main.go
	
.PHONY: burn-with-collateral
burn-with-collateral:
	go run ./Cadence/tasks/burn_with_collateral/main.go

.PHONY: get-social-details
get-social-details:
	go run ./Cadence/tasks/get_social_details/main.go

.PHONY: register-tokens
register-token:
	go run ./Cadence/tasks/register_token/main.go

.PHONY: mint-burn-instant
mint-burn-instant:
	go run ./Cadence/tasks/mint_burn_instant/main.go

.PHONY: mint-burn-instant
burn-exceed-supply:
	go run ./Cadence/tasks/burn_exceed_supply/main.go


