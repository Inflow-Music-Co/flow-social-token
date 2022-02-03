package main

import (
	"log"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	
)

func main() {

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()

	//Setup FUSD Vaults for both accounts
	g.TransactionFromFile("setupFusdVault").SignProposeAndPayAs("first").RunPrintEventsFull();
	g.TransactionFromFile("setupFusdVault").SignProposeAndPayAs("account").RunPrintEventsFull();

	//First Account sets up FUSD Minter
	g.TransactionFromFile("setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull();

	//Admin Account deposits minter into first account
	g.TransactionFromFile("deposit_fusd_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull();

	// First Account Mints and deposits in one transaction
	g.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("100.00").AccountArgument("first").RunPrintEventsFull();

	//Log balance
	fusdFirstAccountBalance := g.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)	

}
