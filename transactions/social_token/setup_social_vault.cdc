import SocialToken from "../../contracts/SocialToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction () {

    prepare(acct: AuthAccount) {

    acct.save(<- SocialToken.createEmptyVault(), to: /storage/R_0x5)
    acct.save(<- SocialToken.createNewMinter(), to: /storage/Minter)
    acct.save(<- SocialToken.createNewBurner(), to: /storage/Burner)
    acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(/public/Burner, target: /storage/Burner)
    acct.link<& SocialToken.Minter{SocialToken.MinterPublic}>(/public/Minter, target:  /storage/Minter)
    acct.link<&SocialToken.Vault{FungibleToken.Balance,SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
    (/public/R_0x5, 
    target: /storage/R_0x5)
    }

    execute {
        log("done")
    }
}