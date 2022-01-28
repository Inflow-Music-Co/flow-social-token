import SocialToken from 0xe03daebed8ca0615
import FungibleToken from 0x01cf0e2f2f715450

transaction () {

    prepare(acct: AuthAccount) {

    acct.save(<- SocialToken.createEmptyVault(), to: /storage/S_0x7)
    acct.save(<- SocialToken.createNewMinter(), to: /storage/SMinter)
    acct.save(<- SocialToken.createNewBurner(), to: /storage/SBurner)
    acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(/public/SBurner, target: /storage/SBurner)
    acct.link<& SocialToken.Minter{SocialToken.MinterPublic}>(/public/SMinter, target:  /storage/SMinter)
    acct.link<&SocialToken.Vault{FungibleToken.Balance,SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
    (/public/S_0x7, 
    target: /storage/S_0x7)
    }

    execute {
    log("done")
    }
}