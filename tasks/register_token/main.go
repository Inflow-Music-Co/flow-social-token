package main

import (
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
	flow.TransactionFromFile("controller/registerToken").SignProposeAndPayAs("account").UFix64Argument("100.00").AccountArgument("account").RunPrintEventsFull()

	//AdminBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("account").RunFailOnError()
	//log.Printf(" ------ Admin Account Balance got all remaining percentage ----- %s", AdminBalance)

}
