import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"


transaction () {

    prepare(acct: AuthAccount) {

    acct.save(<- SocialToken.createEmptyVault(), to: /storage/S_0x5)
    acct.save(<- SocialToken.createNewMinter(), to: /storage/SMinter)
    acct.save(<- SocialToken.createNewBurner(), to: /storage/SBurner)
    acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(/public/SBurner, target: /storage/SBurner)
    acct.link<& SocialToken.Minter{SocialToken.MinterPublic}>(/public/SMinter, target:  /storage/SMinter)
    acct.link<&SocialToken.Vault{FungibleToken.Balance,SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
    (/public/S_0x5, 
    target: /storage/S_0x5)
    }

    execute {
    log("done")
    }
}