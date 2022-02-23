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
		// Pauser
		Argument(cadence.Path{Domain: "storage", Identifier: "USDCPauser-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserCapReceiver-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserUUID-2"}).
		Argument(cadence.Path{Domain: "public", Identifier: "USDCPauserPublicSigner-2"}).
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
		Argument(cadence.Path{Domain: "private", Identifier: "USDCPauserCap-2"}).
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
