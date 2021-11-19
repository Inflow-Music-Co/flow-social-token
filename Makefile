all: storyline
.PHONY: storyline
storyline: 
	go run ./storyline/main.go

.PHONY: event
event:
	go run ./event/main.go


