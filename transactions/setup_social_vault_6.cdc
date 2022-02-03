import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"


transaction () {

    prepare(acct: AuthAccount) {

    acct.save(<- SocialToken.createEmptyVault(), to: /storage/N_0x6)
    acct.save(<- SocialToken.createNewMinter(), to: /storage/NMinter)
    acct.save(<- SocialToken.createNewBurner(), to: /storage/NBurner)
    acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(/public/NBurner, target: /storage/NBurner)
    acct.link<& SocialToken.Minter{SocialToken.MinterPublic}>(/public/NMinter, target:  /storage/NMinter)
    acct.link<&SocialToken.Vault{FungibleToken.Balance,SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
    (/public/N_0x6, 
    target: /storage/N_0x6)
    }

    execute {
    log("done")
    }
}