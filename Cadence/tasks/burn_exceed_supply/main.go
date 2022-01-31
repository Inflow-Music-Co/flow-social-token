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
	flow.TransactionFromFile("setupFusdVault").SignProposeAndPayAs("first").RunPrintEventsFull()
	log.Printf(" ---")

	flow.TransactionFromFile("setupFusdVault").SignProposeAndPayAs("account").RunPrintEventsFull()
	log.Printf(" ---")

	flow.TransactionFromFile("setupFusdVault").SignProposeAndPayAs("second").RunPrintEventsFull() // Artist Vault

	//First Account sets up FUSD Minter
	flow.TransactionFromFile("setup_fusd_minter").SignProposeAndPayAs("first").RunPrintEventsFull()

	//Admin Account deposits minter into first account
	flow.TransactionFromFile("setMinterProxy").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()

	// First Account Mints and deposits in one transaction
	flow.TransactionFromFile("mint_fusd").SignProposeAndPayAs("first").UFix64Argument("10000000.00").AccountArgument("second").RunPrintEventsFull()

	//Log balance
	fusdFirstAccountBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'first account' %s", fusdFirstAccountBalance)

	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	flow.TransactionFromFile("registerToken").SignProposeAndPayAs("account").StringArgument("S").UFix64Argument("1000.00").AccountArgument("first").RunPrintEventsFull()

	//-------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN -----------//
	//-------------------------------------------------//

	//Setup SocialToken Vaults for both accounts
	flow.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("second").RunPrintEventsFull()
	//flow.TransactionFromFile("social_token/setup_social_vault").SignProposeAndPayAs("account").RunPrintEventsFull()

	//First Account sets up Social Minter
	flow.TransactionFromFile("setup_social_minter").StringArgument("S_0x1cf0e2f2f715450").SignProposeAndPayAs("second").RunPrintEventsFull()

	//Admin Account deposits minter into first account
	//	flow.TransactionFromFile("social_token/deposit_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()

	mintQuote := flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("10.00").StringArgument("S_0x1cf0e2f2f715450").RunFailOnError()

	for i := 0; i < 10; i++ {
		// mint social Tokens
		flow.TransactionFromFile("mint_social_token").SignProposeAndPayAs("second").StringArgument("S_0x1cf0e2f2f715450").UFix64Argument("10.00").UFix64Argument(mintQuote.String()).RunPrintEventsFull()
		mintQuote = flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("100.00").StringArgument("S_0x1cf0e2f2f715450").RunFailOnError()
	}

	UserSocialBalance := flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("S_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Social Token Balance of S ----- %s", UserSocialBalance)

	log.Printf(" ------ Social Mint Quote S ----- %s", mintQuote)

	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	flow.TransactionFromFile("registerToken2").SignProposeAndPayAs("account").StringArgument("N").UFix64Argument("10000000.00").AccountArgument("second").RunPrintEventsFull()
	//First Account sets up Social Minter
	flow.TransactionFromFile("setup_social_minter2").StringArgument("N_0x179b6b1cb6755e31").SignProposeAndPayAs("second").RunPrintEventsFull()
	mintQuote = flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("10.00").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ Social Mint Quote N Before ----- %s", mintQuote)

	flow.TransactionFromFile("mint_social_token").SignProposeAndPayAs("second").StringArgument("N_0x1cf0e2f2f715450").UFix64Argument("10.00").UFix64Argument(mintQuote.String()).RunPrintEventsFull()
	mintQuote = flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("10.00").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ Social Mint Quote N After ----- %s", mintQuote)

	UserSocialBalance = flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("S_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ User Social Token Balance of S ----- %s", UserSocialBalance)

	UserSocialBalance = flow.ScriptFromFile("get_social_balance").AccountArgument("second").StringArgument("N_0x179b6b1cb6755e31").RunFailOnError()
	log.Printf(" ------ User Social Token Balance of N ----- %s", UserSocialBalance)

}
