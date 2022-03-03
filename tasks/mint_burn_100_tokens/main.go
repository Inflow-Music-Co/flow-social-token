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

	//Setup FUSD Vaults for all accounts
	log.Printf(" ------")
	flow.TransactionFromFile("setup_fusd_vault").SignProposeAndPayAs("first").RunPrintEventsFull()
	log.Printf(" ---")

	flow.TransactionFromFile("setup_fusd_vault").SignProposeAndPayAs("account").RunPrintEventsFull()
	log.Printf(" ---")

	flow.TransactionFromFile("setup_fusd_vault").SignProposeAndPayAs("second").RunPrintEventsFull() // Artist Vault

	//First Account sets up FUSD Minter
	flow.TransactionFromFile("setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull()

	//Admin Account deposits minter into first account
	flow.TransactionFromFile("setup_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()

	// First Account Mints and deposits in one transaction
	flow.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("100.00").AccountArgument("first").RunPrintEventsFull()

	flow.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("100.00").AccountArgument("second").RunPrintEventsFull()

	//Log balance
	fusdFirstAccountBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)

	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	flow.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("TestSymbol").UFix64Argument("1000.00").AccountArgument("first").RunPrintEventsFull()

	//add setfeeSplitterDetail for given Token
	flow.TransactionFromFile("setfeeSplitterDetail").SignProposeAndPayAs("account").StringArgument("TestSymbol_0x1cf0e2f2f715450").AccountArgument("first").RunPrintEventsFull()
	
	//--------------------------------------------------//
	//-- SETUP Admin and Add Capability of Controller --//
	//--------------------------------------------------//
	flow.TransactionFromFile("setup_admin_account").SignProposeAndPayAs("account").RunPrintEventsFull()

	flow.TransactionFromFile("add_admin_account").SignProposeAndPayAs("account").AccountArgument("account").RunPrintEventsFull()
	//-------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN -----------//
	//-------------------------------------------------//

	//Setup SocialToken Vaults for both accounts
	flow.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunPrintEventsFull()
	//Admin Account deposits minter into first account
	//	flow.TransactionFromFile("social_token/deposit_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()

	mintQuote := flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("100.00").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()

	// mint social Tokens
	flow.TransactionFromFile("mint_social_token").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").UFix64Argument("100.00").UFix64Argument("100.00").RunPrintEventsFull()

	UserSocialBalance := flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Social Token Balance of S ----- %s", UserSocialBalance)

	log.Printf(" ------ Social Mint Quote S ----- %s", mintQuote)

	//reserve after buring social tokens
	reserve := flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ reserve before buring social tokens TestSymbol_0x1cf0e2f2f715450----- %s", reserve)

	// burn social Tokens
	flow.TransactionFromFile("burn_social_token").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").UFix64Argument("100.00000000").RunPrintEventsFull()

	//reserve after buring social tokens
	reserve = flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ reserve after buring social tokens TestSymbol_0x1cf0e2f2f715450----- %s", reserve)
	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	flow.TransactionFromFile("register_token_Inflow").SignProposeAndPayAs("account").StringArgument("N").UFix64Argument("10000000.00").AccountArgument("second").RunPrintEventsFull()
	//First Account sets up Social Minter
	mintQuote = flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("100.00").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ Social Mint Quote N Before ----- %s", mintQuote)

	//-------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN -----------//
	//-------------------------------------------------//

	//Setup SocialToken Vaults for both accounts
	flow.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("first").StringArgument("N_0x179b6b1cb6755e31").RunPrintEventsFull()

	// mint tokens
	flow.TransactionFromFile("mint_social_token").SignProposeAndPayAs("first").StringArgument("N_0x179b6b1cb6755e31").UFix64Argument("100.00").UFix64Argument("100.00").RunPrintEventsFull()

	//reserve after buring social tokens
	reserve = flow.ScriptFromFile("get_reserve").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ reserve before buring social tokens N_0x179b6b1cb6755e31----- %s", reserve)


	// burn social Tokens
	flow.TransactionFromFile("burn_social_token").SignProposeAndPayAs("first").StringArgument("N_0x179b6b1cb6755e31").UFix64Argument("100.00000000").RunPrintEventsFull()

	//reserve after buring social tokens
	reserve = flow.ScriptFromFile("get_reserve").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ reserve after buring social tokens N_0x179b6b1cb6755e31----- %s", reserve)

	UserSocialBalance = flow.ScriptFromFile("get_social_balance").AccountArgument("first").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ User Social Token Balance of first account ----- %s", UserSocialBalance)

	UserSocialBalance = flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Social Token Balance of second account ----- %s", UserSocialBalance)

	// Get the balance of all accounts
	ArtistAccountBalanceFUSD := flow.ScriptFromFile("get_fusd_balance").AccountArgument("second").RunFailOnError()
	log.Printf(" ------ User FUSD Balance of second account ----- %s", ArtistAccountBalanceFUSD)

	//Log balance
	fusdFirstAccountBalance = flow.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf(" ------ User FUSD Balance of first account ----- %s", fusdFirstAccountBalance)

}
