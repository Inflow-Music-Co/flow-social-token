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

.PHONY: burn-with-collateral
burn-with-collateral:
	go run ./tasks/burn_with_collateral/main.go



