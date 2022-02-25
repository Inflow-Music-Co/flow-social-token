package main

import (
	"fmt"
	"log"
	"bytes"
	"io/ioutil"
	"os"
	"time"

	"text/template"
	"encoding/hex"

	"github.com/onflow/cadence"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
	
	"github.com/onflow/flow-go-sdk"
)

func main() {

	//This method starts an in memory flow emulator
	// - it then looks at all the contracts in the deployment block for emulator and deploys them
	// - then it looks at all the accounts that does not have contracts in them and create those accounts. These can be used as stakeholders in your "storyline" below.
	// - when referencing accounts in the "storyline" below note that the default option is to prepened the network to the account name, This is done so that it is easy to run a storyline against emulator, tesnet and mainnet. This can be disabled with the `DoNotPrependNetworkToAccountNames` method on the g object below.


	g := gwtf.NewGoWithTheFlowInMemoryEmulator()
	
	_, err := DeployFiatTokenContract(g, "account", "USDC", "0.1.0")
	fmt.Println("err: ", err)
	if err != nil {
		log.Fatal("Cannot deploy contract")
	}
	x, err := DeploySocialTokenContract(g, "testaccount", "SocialToken")
	if err != nil {
		log.Fatal("Cannot deploy socialToken contract", err)
	}else{
		fmt.Println("socialToken deployed successfully", x)
	}
	multiSigPubKeys, multiSigKeyWeights, multiSigAlgos := GetMultiSigKeys(g)


	//Setup FUSD Vaults for all accounts
	log.Printf(" ------")
	g.TransactionFromFile("create_usdc_vault").SignProposeAndPayAs("first").RunPrintEventsFull()
	log.Printf(" ---")

	g.TransactionFromFile("create_usdc_vault").SignProposeAndPayAs("account").RunPrintEventsFull() // Artist Vault

	g.TransactionFromFile("create_usdc_vault").SignProposeAndPayAs("blocklister").RunPrintEventsFull() // Artist Vault

	//create new minter
	g.TransactionFromFile("create_new_minter").SignProposeAndPayAs("minter").AccountArgument("minter").Argument(cadence.NewArray(multiSigPubKeys)).Argument(cadence.NewArray(multiSigKeyWeights)).Argument(cadence.NewArray(multiSigAlgos)).RunPrintEventsFull()

	//create new minter controller 
	g.TransactionFromFile("create_new_minterController").SignProposeAndPayAs("minterController1").AccountArgument("minterController1").Argument(cadence.NewArray(multiSigPubKeys)).Argument(cadence.NewArray(multiSigKeyWeights)).Argument(cadence.NewArray(multiSigAlgos)).RunPrintEventsFull()

	//get minter resourceid 
	minterResource := g.ScriptFromFile("get_resource").AccountArgument("minter").StringArgument("Minter").RunFailOnError()
	//fmt.Printf("t1: %T\n", minterResource)
	fmt.Println("minterResource", minterResource)
	//get minter controller resourceid 
	minterConrollerResource := g.ScriptFromFile("get_resource").AccountArgument("minterController1").StringArgument("MinterController").RunFailOnError()
	//fmt.Printf("t1: %T\n", minterConrollerResource)
	fmt.Println("minterResource", minterConrollerResource)
	minter := uint64(114)
	minterController := uint64(115)
	//configure minter controller to manage the minter
	g.TransactionFromFile("configure_minter_controller").SignProposeAndPayAs("account").UInt64Argument(minter).UInt64Argument(minterController).RunPrintEventsFull()

	//configure allowance
	g.TransactionFromFile("configure_allowance").SignProposeAndPayAs("minterController1").UFix64Argument("2500000000.00").RunPrintEventsFull()

	// first Account Mints and deposits in one transaction
	//g.TransactionFromFile("mint_usdc").SignProposeAndPayAs("minter").UFix64Argument("2500000000.00").AccountArgument("blocklister").RunPrintEventsFull()

	g.TransactionFromFile("mint_usdc").SignProposeAndPayAs("minter").UFix64Argument("2500000000.00").AccountArgument("first").RunPrintEventsFull()
	//-------------------------------------------------//
	//--------- Register Account -----------//
	//-------------------------------------------------//

	//Register Token for a new account
	g.TransactionFromFile("register_token").SignProposeAndPayAs("account").StringArgument("TestSymbol").UFix64Argument("10000000.00").AccountArgument("blocklister").RunPrintEventsFull()

	//add setfeeSplitterDetail for given Token 
	g.TransactionFromFile("setfeeSplitterDetail").SignProposeAndPayAs("account").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").AccountArgument("blocklister").RunPrintEventsFull()
	//--------------------------------------------------//
	//-- SETUP Admin and Add Capability of Controller --//
	//--------------------------------------------------//
	g.TransactionFromFile("setup_admin_account").SignProposeAndPayAs("testaccount").RunPrintEventsFull()

	g.TransactionFromFile("add_admin_account").SignProposeAndPayAs("account").AccountArgument("testaccount").RunPrintEventsFull()

	//--------------------------------------------------//
	//--------- SETUP AND MINT SOCIAL TOKEN ------------//
	//--------------------------------------------------//

	//Setup SocialToken Vaults for both accounts
	g.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("first").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunPrintEventsFull()
	g.TransactionFromFile("setup_social_vault").SignProposeAndPayAs("blocklister").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunPrintEventsFull()
	//flow.TransactionFromFile("social_token/setup_social_vault").SignProposeAndPayAs("account").RunPrintEventsFull()

	mintQuote := g.ScriptFromFile("get_social_mint_quote").UFix64Argument("10000000.00").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ Social Mint Quote ----- %s", mintQuote)
	
	//Log balance
	usdcfirstAccountBalance := g.ScriptFromFile("get_usdc_balance").AccountArgument("first").RunFailOnError()
	log.Printf("USDC balance of account 'first account' %s", usdcfirstAccountBalance)
	
	// mint social Tokens
	g.TransactionFromFile("mint_Social_token_usdc").SignProposeAndPayAs("first").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").UFix64Argument("10000000.00").UFix64Argument(mintQuote.String()).RunPrintEventsFull()

	log.Printf(" ------ Social Mint Quote ----- %s", mintQuote)
	//Admin Account deposits minter into first account
	//	flow.TransactionFromFile("social_token/deposit_social_minter").SignProposeAndPayAs("account").AccountArgument("first").RunPrintEventsFull()
	TokenDetails := g.ScriptFromFile("get_social_details").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ Social Token Details ----- %s", TokenDetails)

	// Get the balance of all accounts
	ArtistAccountBalance := g.ScriptFromFile("get_issued_supply").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ get Issued Supply ----- %s", ArtistAccountBalance)

	BurnPrice := g.ScriptFromFile("get_social_burn_quote").UFix64Argument("10000000.00").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ first Burn Price ----- %s", BurnPrice)

	firstSocialBalance := g.ScriptFromFile("get_social_balance").AccountArgument("first").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ first Social Token Balance ----- %s", firstSocialBalance)

	//reserve before burning social tokens
	reserve := g.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ reserve before buring social tokens----- %s", reserve)

	// burn social Tokens
	g.TransactionFromFile("burn_social_token").SignProposeAndPayAs("first").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").UFix64Argument("10000000.00000000").RunPrintEventsFull()
	
	//reserve before burning social tokens
	reserve = g.ScriptFromFile("get_reserve").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ reserve after buring social tokens----- %s", reserve)
	
	// Get the balance of all accounts
	ArtistAccountBalanceUSDC := g.ScriptFromFile("get_usdc_balance").AccountArgument("blocklister").RunFailOnError()
	log.Printf(" ------ first USDC Balance after burning ----- %s", ArtistAccountBalanceUSDC)

	ArtistAccountBalance = g.ScriptFromFile("get_social_balance").AccountArgument("blocklister").StringArgument("TestSymbol_0xf3fcd2c1a78f5eee").RunFailOnError()
	log.Printf(" ------ first Social Balance after burning ----- %s", ArtistAccountBalance)

	//Log balance
	fusdfirstAccountBalance := g.ScriptFromFile("get_usdc_balance").AccountArgument("first").RunFailOnError()
	log.Printf("FUSD balance of account 'artist account' %s", fusdfirstAccountBalance)

	AdminBalance := g.ScriptFromFile("get_usdc_balance").AccountArgument("account").RunFailOnError()
	log.Printf("Admin balance of account  %s", AdminBalance)

}

// Useful multisig accounts
// These are named by the weights
// i.e. Account500_1 has a weight of 500.0
const Acct1000 = "w-1000"
const Acct500_1 = "w-500-1"
const Acct500_2 = "w-500-2"
const Acct250_1 = "w-250-1"
const Acct250_2 = "w-250-2"
const Config = ".././flow.json"

var FlowJSON []string = []string{Config}

type Addresses struct {
	FungibleToken      string
	FiatTokenInterface string
	FiatToken          string
	OnChainMultiSig    string
}

type TestEvent struct {
	Name   string
	Fields map[string]string
}

var addresses Addresses

func ParseCadenceTemplate(templatePath string) []byte {
	fb, err := ioutil.ReadFile(templatePath)
	if err != nil {
		panic(err)
	}

	tmpl, err := template.New("Template").Parse(string(fb))
	if err != nil {
		panic(err)
	}

	// Addresss for emulator are
	// addresses = Addresses{"ee82856bf20e2aa6", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450", "01cf0e2f2f715450"}
	addresses = Addresses{os.Getenv("FUNGIBLE_TOKEN_ADDRESS"), os.Getenv("OWNER_ADDRESS"), os.Getenv("OWNER_ADDRESS"), os.Getenv("OWNER_ADDRESS")}

	buf := &bytes.Buffer{}
	err = tmpl.Execute(buf, addresses)
	if err != nil {
		panic(err)
	}

	return buf.Bytes()
}


func GetMultiSigKeys(g *gwtf.GoWithTheFlow) (MultiSigPubKeys []cadence.Value, MultiSigKeyWeights []cadence.Value, MultiSigAlgos []cadence.Value) {
	pk1000 := g.Account(Acct1000).Key().ToConfig().PrivateKey.PublicKey().String()
	pk500_1 := g.Account(Acct500_1).Key().ToConfig().PrivateKey.PublicKey().String()
	pk500_2 := g.Account(Acct500_2).Key().ToConfig().PrivateKey.PublicKey().String()
	pk250_1 := g.Account(Acct250_1).Key().ToConfig().PrivateKey.PublicKey().String()
	pk250_2 := g.Account(Acct250_2).Key().ToConfig().PrivateKey.PublicKey().String()

	w1000, _ := cadence.NewUFix64("1000.0")
	w500, _ := cadence.NewUFix64("500.0")
	w250, _ := cadence.NewUFix64("250.0")

	MultiSigPubKeys = []cadence.Value{
		cadence.String(pk1000[2:]),
		cadence.String(pk500_1[2:]),
		cadence.String(pk500_2[2:]),
		cadence.String(pk250_1[2:]),
		cadence.String(pk250_2[2:]),
	}

	MultiSigAlgos = []cadence.Value{
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
		cadence.NewUInt8(1),
	}
	MultiSigKeyWeights = []cadence.Value{w1000, w500, w500, w250, w250}
	return
}

func ParseTestEvents(events []flow.Event) (formatedEvents []*gwtf.FormatedEvent) {
	for _, e := range events {
		formatedEvents = append(formatedEvents, gwtf.ParseEvent(e, uint64(0), time.Now(), nil))
	}
	return
}

func DeploySocialTokenContract(g *gwtf.GoWithTheFlow, ownerAcct string,tokenName string) (events []*gwtf.FormatedEvent, err error){
	
	contractCode := ParseCadenceTemplate("././contracts/SocialToken.cdc")
	fmt.Println("hello we are in social token")
	
	txFilename := "deploy_social_token"

	fmt.Println("parse socialToken template", txFilename)
	//code := ParseCadenceTemplate(txFilename)
	encodedStr := hex.EncodeToString(contractCode)
	fmt.Println("template encoded")

	e, err := g.TransactionFromFile(txFilename).
		SignProposeAndPayAs(ownerAcct).
		StringArgument("SocialToken").
		StringArgument(encodedStr).
		RunE()
	gwtf.PrintEvents(e, map[string][]string{})
	events = ParseTestEvents(e)

	return
}
func DeployFiatTokenContract(
	g *gwtf.GoWithTheFlow,
	ownerAcct string, tokenName string, version string) (events []*gwtf.FormatedEvent, err error) {
	
	contractCode := ParseCadenceTemplate("././contracts/FiatToken.cdc")
	
	
	txFilename := "deploy_contract_with_auth"
	fmt.Println("parse template", txFilename)
	//code := ParseCadenceTemplate(txFilename)
	encodedStr := hex.EncodeToString(contractCode)

	if g.Network == "emulator" {
		g.CreateAccounts("emulator-account")
	}
	fmt.Println("Accounts created")
	multiSigPubKeys, multiSigKeyWeights, multiSigAlgos := GetMultiSigKeys(g)
	fmt.Println("keys created")
	e, err := g.TransactionFromFile(txFilename).
		SignProposeAndPayAs(ownerAcct).
		StringArgument("FiatToken").
		StringArgument(encodedStr).
		// Vault
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCVault-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultBalance-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCVaultReceiver-2"}).

		// Blocklist executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCBlocklistExe-2"}).
		// Blocklister
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCBlocklister-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCBlocklisterPublicSigner-2"}).
		// Pause executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPauseExe-2"}).
		// Pafirst
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPafirst-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPafirstCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPafirstUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPafirstPublicSigner-2"}).
		// Admin executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCAdminExe-2"}).
		//Admin
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCAdmin-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCAdminCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCAdminUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCAdminPublicSigner-2"}).
		// Owner executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCOwnerExe-2"}).
		// Owner
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCOwner-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCOwnerCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCOwnerUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCOwnerPubSigner-2"}).
		// Master Minter Executor
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMasterMinterExe-2"}).
		// Master Minter
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMasterMinter-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterPublicSigner-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMasterMinterUUID-2"}).
		// Minter Controller
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMinterController-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterControllerUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterControllerPublicSigner-2"}).
		// Minter
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCMinter-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCMinterUUID-2"}).
		// Initial resource capabilities
		Argument(cadence.Path{Domain: "private", Identifier: "USDCAdminCap-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCOwnerCap-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCMasterMinterCap-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCPafirstCap-2"}).
		Argument(cadence.Path{Domain: "private", Identifier: "USDCBlocklisterCap-2"}).
		StringArgument(tokenName).
		StringArgument(version).
		UFix64Argument("1000000000.00000000").
		BooleanArgument(false).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		Argument(cadence.NewArray(multiSigAlgos)).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		Argument(cadence.NewArray(multiSigAlgos)).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		Argument(cadence.NewArray(multiSigAlgos)).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		Argument(cadence.NewArray(multiSigAlgos)).
		Argument(cadence.NewArray(multiSigPubKeys)).
		Argument(cadence.NewArray(multiSigKeyWeights)).
		Argument(cadence.NewArray(multiSigAlgos)).
		RunE()
	gwtf.PrintEvents(e, map[string][]string{})
	events = ParseTestEvents(e)

	return
}

func UpgradeFiatTokenContract(
	g *gwtf.GoWithTheFlow,
	ownerAcct string, version string) (events []*gwtf.FormatedEvent, err error) {
	contractCode := ParseCadenceTemplate("././contracts/FiatToken.cdc")
	txFilename := "upgrade_contract.cdc"
	//code := ParseCadenceTemplate(txFilename)
	encodedStr := hex.EncodeToString(contractCode)

	e, err := g.TransactionFromFile(txFilename).
		SignProposeAndPayAs(ownerAcct).
		StringArgument("FiatToken").
		StringArgument(encodedStr).
		StringArgument(version).
		RunE()
	gwtf.PrintEvents(e, map[string][]string{})
	events = ParseTestEvents(e)

	return
}
