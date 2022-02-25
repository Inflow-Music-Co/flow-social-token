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
	flow.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("2500000000.00").AccountArgument("second").RunPrintEventsFull()


	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	flow.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("TestSymbol").UFix64Argument("10000000.00").AccountArgument("first").RunPrintEventsFull()
	
	//add setfeeSplitterDetail for given Token 
	flow.TransactionFromFile("setfeeSplitterDetail").SignProposeAndPayAs("account").StringArgument("TestSymbol_0x1cf0e2f2f715450").AccountArgument("first").RunPrintEventsFull()
	
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
	log.Printf(" ------ Social Mint Quote ----- %s", mintQuote)
	
	//Log balance
	fusdFirstAccountBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("second").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)
	
	// mint social Tokens
	flow.TransactionFromFile("mint_social_token").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").UFix64Argument("10000000.00").UFix64Argument(mintQuote.String()).RunPrintEventsFull()

	log.Printf(" ------ Social Mint Quote ----- %s", mintQuote)
	//Admin Account deposits minter into first account
	//	flow.TransactionFromFile("social_token/deposit_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()
	TokenDetails := flow.ScriptFromFile("get_social_details").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ Social Token Details ----- %s", TokenDetails)

	// Get the balance of all accounts
	ArtistAccountBalance := flow.ScriptFromFile("get_issued_supply").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ get Issued Supply ----- %s", ArtistAccountBalance)

	BurnPrice := flow.ScriptFromFile("get_social_burn_quote").UFix64Argument("10000000.00").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Burn Price ----- %s", BurnPrice)

	UserSocialBalance := flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Social Token Balance ----- %s", UserSocialBalance)

	//reserve before burning social tokens
	reserve := flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ reserve before buring social tokens----- %s", reserve)

	// burn social Tokens
	flow.TransactionFromFile("burn_social_token").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").UFix64Argument("10000000.00000000").RunPrintEventsFull()
	
	//reserve before burning social tokens
	reserve = flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ reserve after buring social tokens----- %s", reserve)
	
	// Get the balance of all accounts
	ArtistAccountBalanceFUSD := flow.ScriptFromFile("get_fusd_balance").AccountArgument("second").RunFailOnError()
	log.Printf(" ------ User FUSD Balance after burning ----- %s", ArtistAccountBalanceFUSD)

	ArtistAccountBalance = flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Social Balance after burning ----- %s", ArtistAccountBalance)

	//Log balance
	fusdFirstAccountBalance = flow.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'artist account' %s", fusdFirstAccountBalance)

	AdminBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("account").RunFailOnError()
	log.Printf("Admin balance of account  %s", AdminBalance)

}
