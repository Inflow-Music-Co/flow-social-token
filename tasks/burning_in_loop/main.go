package main

import (
	"log"
	"strconv"
	"time"

	"github.com/360EntSecGroup-Skylar/excelize"
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

	mintTokens := "10000000.0"
	
	mintQuote := flow.ScriptFromFile("get_social_mint_quote").UFix64Argument("10000000.0").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()

	// mint social Tokens
	flow.TransactionFromFile("mint_social_token").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").UFix64Argument(mintTokens).UFix64Argument(mintQuote.String()).RunPrintEventsFull()
	log.Printf(" ------ Social Mint Quote ----- %s", mintQuote)

	//reserve before burning social tokens
	reserve := flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
	log.Printf(" ------ reserve before buring social tokens----- %s", reserve)

	//create new file
	f := excelize.NewFile()
	//set column names
    f.SetCellValue("Sheet1", "A1", "Supply")
    f.SetCellValue("Sheet1", "B1", "Reserve")
    f.SetCellValue("Sheet1", "C1", "User_balance")
	f.SetCellValue("Sheet1", "D1", "Burn_token")
    f.SetCellValue("Sheet1", "E1", "Total_token_burn_Price")
    f.SetCellValue("Sheet1", "F1", "Single_token_burn_price")
	f.SetCellValue("Sheet1", "G1", "current_Time")

	// burn social Tokens
	j :=2
	burnTokens := "100000.00" 

	for i := 0; i < 100; i++ {
		BurnPrice := flow.ScriptFromFile("get_social_burn_quote").UFix64Argument(burnTokens).StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
		log.Printf(" ------ Social Mint Quote burn price %d iteration ----- %s", i, BurnPrice)
		
		Reserve1 := flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
		log.Printf(" ------ Social burn reserve before %d  iteration ----- %s", i, Reserve1)

		flow.TransactionFromFile("burn_social_token").SignProposeAndPayAs("second").StringArgument("TestSymbol_0x1cf0e2f2f715450").UFix64Argument(burnTokens).RunPrintEventsFull()
		
		//reserve after burning social tokens
		reserve = flow.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
		log.Printf(" ------ reserve after buring social tokens----- %s", reserve)

		//total after burning social tokens
		supply := flow.ScriptFromFile("get_issued_supply").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
		log.Printf(" ------ reserve after buring social tokens----- %s", supply)
		
		//Log balance
		fusdSecondAccountBalance := flow.ScriptFromFile("get_fusd_balance").AccountArgument("second").RunFailOnError()
		log.Printf("FUSD balance of account 'first account' %s", fusdSecondAccountBalance)
		
		j +=1
		k := strconv.Itoa(j)
		now := time.Now()

		if i== 99 {
			f.SetCellValue("Sheet1", "F" + k, 0)
		}else{
			SingleBurnPrice := flow.ScriptFromFile("get_social_burn_quote").UFix64Argument("1.00").StringArgument("TestSymbol_0x1cf0e2f2f715450").RunFailOnError()
			log.Printf(" ------ Social Mint Quote burn price %d iteration ----- %s", i, SingleBurnPrice)
			f.SetCellValue("Sheet1", "F" + k, SingleBurnPrice)
		}
		
		f.SetCellValue("Sheet1", "A" + k, supply)
		f.SetCellValue("Sheet1", "B" + k, reserve)
		f.SetCellValue("Sheet1", "C" + k, fusdSecondAccountBalance)
		f.SetCellValue("Sheet1", "D" + k, burnTokens)
		f.SetCellValue("Sheet1", "E" + k, BurnPrice)
		f.SetCellValue("Sheet1", "G" + k, now.Format(time.ANSIC))

	}
    if err := f.SaveAs("bondingCurve.xlsx"); err != nil {
        log.Fatal(err)
    }
}
