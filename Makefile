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


