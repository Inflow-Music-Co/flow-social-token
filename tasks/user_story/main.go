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

	g := gwtf.NewGoWithTheFlowInMemoryEmulator()

	//-------------------------------------------------//
	// ------ SETUP AND MINT FUSD ---------------------//
	//-------------------------------------------------//

	//Setup FUSD Vaults for both accounts
	g.TransactionFromFile("setup_fusd_vault").SignProposeAndPayAs("first").RunPrintEventsFull();
	g.TransactionFromFile("setup_fusd_vault").SignProposeAndPayAs("account").RunPrintEventsFull();

	//First Account sets up FUSD Minter
	g.TransactionFromFile("setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull();

	//Admin Account deposits minter into first account
	g.TransactionFromFile("deposit_fusd_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull();

	//first account Mints and deposits in one transaction
	g.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("999999.00").AccountArgument("first").RunPrintEventsFull();

	//Log balance
	fusdFirstAccountBalance := g.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)	

	//-------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN -----------//
	//-------------------------------------------------//

	//Setup SocialToken Vaults for both accounts
	g.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("first").RunPrintEventsFull()
	g.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("account").RunPrintEventsFull()

	//First Account sets up Social Minter
	g.TransactionFromFile("setup_social_minter").SignProposeAndPayAs("first").RunPrintEventsFull()

	//Admin Account deposits  minter into first account
	g.TransactionFromFile("deposit_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()
	
	//first account mints and deposits in one transaction
	g.TransactionFromFile("mint_social").SignProposeAndPayAs("first").AccountArgument("first").UFix64Argument("33.0").RunPrintEventsFull()

	// script returns social token balanace for account Account
	AccountSocialBalance := g.ScriptFromFile("get_social_balance").AccountArgument("account").RunFailOnError()
	log.Printf("Script returned %s", AccountSocialBalance)

	// script returns social token balanace for account First
	FirstSocialBalance := g.ScriptFromFile("get_social_balance").AccountArgument("first").RunFailOnError()
	log.Printf("Script returned %s", FirstSocialBalance)

	//-------------------------------------------------//
	//--------- SETUP AND BURN SOCIAL TOKEN -----------//
	//-------------------------------------------------//

	//First Account sets up Social Minter
	g.TransactionFromFile("setup_social_burner").SignProposeAndPayAs("first").RunPrintEventsFull()

	//Admin Account deposits  burner into first account
	g.TransactionFromFile("deposit_social_burner").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()

	//First account burns tokens
	g.TransactionFromFile("burn_tokens").SignProposeAndPayAs("first").UFix64Argument("1.111111").RunPrintEventsFull()

	//script returns social balance after burn for account first
	resultAccountEnd := g.ScriptFromFile("get_social_balance").AccountArgument("first").RunFailOnError()
	log.Printf("Script returned %s", resultAccountEnd)
	

}
