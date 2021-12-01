package main

import (
	"log"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	
)

func main() {

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()

	//Setup FUSD Vaults for both accounts
	g.TransactionFromFile("fusd/setup_fusd_vault").SignProposeAndPayAs("first").RunPrintEventsFull();
	g.TransactionFromFile("fusd/setup_fusd_vault").SignProposeAndPayAs("account").RunPrintEventsFull();

	//First Account sets up FUSD Minter
	g.TransactionFromFile("fusd/setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull();

	//Admin Account deposits minter into first account
	g.TransactionFromFile("fusd/deposit_fusd_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull();

	// First Account Mints and deposits in one transaction
	g.TransactionFromFile("fusd/mint_fusd").SignProposeAndPayAs("first").UFix64Argument(100.00).AccountArgument("first").RunPrintEventsFull();

	//Log balance
	fusdFirstAccountBalance := g.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)	

}
