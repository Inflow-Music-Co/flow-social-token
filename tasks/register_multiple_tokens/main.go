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

	//Register New Token//

	//Register Token for a new account
	flow.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("S").UFix64Argument("1000.00").AccountArgument("first").RunPrintEventsFull()
	
	//Register Token for another account with different maximum supply
	flow.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("X").UFix64Argument("10000000.00").AccountArgument("second").RunPrintEventsFull()

	//Register Token for another account with strange maximum supply
	flow.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("STRANGE").UFix64Argument("3829107348.00").AccountArgument("3").RunPrintEventsFull()
	
	TokenDetailsFirst := flow.ScriptFromFile("get_social_details").StringArgument("S_0x1cf0e2f2f715450").RunFailOnError()
	TokenDetailsSecond := flow.ScriptFromFile("get_social_details").StringArgument("X_0x179b6b1cb6755e31").RunFailOnError()
	TokenDetailsThird := flow.ScriptFromFile("get_social_details").StringArgument("STRANGE_0xf3fcd2c1a78f5eee").RunFailOnError()
	
	log.Printf(" ------ Social Token Details first Artist----- %s", TokenDetailsFirst)
	log.Printf(" ------ Social Token Details second Artist----- %s", TokenDetailsSecond)
	log.Printf(" ------ Social Token Details second Artist----- %s", TokenDetailsThird)


	log.Printf(" ------")
	flow.TransactionFromFile("setup_fusd_vault").SignProposeAndPayAs("first").RunPrintEventsFull()
	log.Printf(" ---")

	//First Account sets up FUSD Minter
	flow.TransactionFromFile("setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull()

	//Admin Account deposits minter into first account
	flow.TransactionFromFile("setup_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()

	// First Account Mints and deposits in one transaction
	flow.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("10000000.00").AccountArgument("second").RunPrintEventsFull()

	//Log balance
	fusdFirstAccountBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)
	
	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	flow.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("TestSymbol").UFix64Argument("10000000.00").AccountArgument("first").RunPrintEventsFull()

	
	//--------------------------------------------------//
	//-- SETUP Admin and Add Capability of Controller --//
	//--------------------------------------------------//
	flow.TransactionFromFile("setup_admin_account").SignProposeAndPayAs("account").RunPrintEventsFull()
	
	flow.TransactionFromFile("add_admin_account").SignProposeAndPayAs("account").AccountArgument("account").RunPrintEventsFull()

	//--------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN ------------//
	//--------------------------------------------------//

	//Setup SocialToken Vaults for both accounts
	flow.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunPrintEventsFull()
	//flow.TransactionFromFile("social_token/setup_social_vault").SignProposeAndPayAs("account").RunPrintEventsFull()

	mintQuote := flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("10000000.00").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	

	log.Printf(" ------ mintQuote is ----- %s", mintQuote)

}
