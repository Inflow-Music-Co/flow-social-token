package main

import (
	"log"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	
)

func main() {

	//This method starts an in memory flow emulator
	// - it then looks at all the contracts in the deployment block for emulator and deploys them
	// - then it looks at all the accounts that does not have contracts in them and create those accounts. These can be used as stakeholders in your "storyline" below.
	// - when referencing accounts in the "storyline" below note that the default option is to prepened the network to the account name, This is done so that it is easy to run a storyline against emulator, tesnet and mainnet. This can be disabled with the `DoNotPrependNetworkToAccountNames` method on the g object below.

	flow := gwtf.NewGoWithTheFlowInMemoryEmulator()

	//FUSD// 

	//Setup FUSD Vaults for both accounts
	flow.TransactionFromFile("fusd/setup_fusd_vault").SignProposeAndPayAs("first").RunPrintEventsFull();
	flow.TransactionFromFile("fusd/setup_fusd_vault").SignProposeAndPayAs("account").RunPrintEventsFull();

	//First Account sets up FUSD Minter
	flow.TransactionFromFile("fusd/setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull();

	//Admin Account deposits minter into first account
	flow.TransactionFromFile("fusd/deposit_fusd_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull();

	// First Account Mints and deposits in one transaction
	flow.TransactionFromFile("fusd/mint_fusd").SignProposeAndPayAs("first").UFix64Argument("100.00").AccountArgument("first").RunPrintEventsFull();

	//Log balance
	fusdFirstAccountBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)

	//-------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN -----------//
	//-------------------------------------------------//

	

	//Setup SocialToken Vaults for both accounts
	flow.TransactionFromFile("social_token/setup_social_vault").SignProposeAndPayAs("first").RunPrintEventsFull()
	flow.TransactionFromFile("social_token/setup_social_vault").SignProposeAndPayAs("account").RunPrintEventsFull()

	//First Account sets up Social Minter
	flow.TransactionFromFile("social_token/setup_social_minter").SignProposeAndPayAs("first").RunPrintEventsFull()

	//Admin Account deposits minter into first account
	flow.TransactionFromFile("social_token/deposit_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull();

	//Get the mintQoute for the specificed amount of socialTokens
	mintQuote := flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("3.3333").RunFailOnError()
	log.Printf(" ------ MINT QUOTE ----- %s", mintQuote)

	flow.TransactionFromFile("social_token/mint_social_token").SignProposeAndPayAs("first").UFix64Argument("3.3333").UFix64Argument("6.6666").RunPrintEventsFull()	



}
