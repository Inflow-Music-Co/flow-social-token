import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from "../contracts/SocialToken.cdc"


transaction () {

    prepare(acct: AuthAccount) {
    acct.save(<- SocialToken.createEmptyVault(), to: /storage/S_0x5)
    acct.save(<- SocialToken.createNewMinter(), to: /storage/Minter)
    acct.save(<- SocialToken.createNewBurner(), to: /storage/RBurner)
    acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(/public/RBurner, target: /storage/RBurner)
    acct.link<& SocialToken.Minter{SocialToken.MinterPublic}>(/public/Minter, target:  /storage/Minter)
    acct.link<&SocialToken.Vault{FungibleToken.Balance,SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
    (/public/S_0x5, 
    target: /storage/S_0x5)
    }

    execute {
    log("done")
    }
}