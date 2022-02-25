import SocialToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7

transaction (tokenId: String) {

    prepare(acct: AuthAccount) {

        let tokenDetails = Controller.getTokenDetails(tokenId)

        acct.save(<- SocialToken.createEmptyVault(), to: tokenDetails.tokenResourceStoragePath)
        acct.save(<- SocialToken.createNewMinter(), to: tokenDetails.socialMinterStoragePath)
        acct.save(<- SocialToken.createNewBurner(), to: tokenDetails.socialBurnerStoragePath)
        acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(tokenDetails.socialBurnerPublicPath, target: tokenDetails.socialBurnerStoragePath)
        acct.link<&SocialToken.Minter{SocialToken.MinterPublic}>(tokenDetails.socialMinterPublicPath, target:  tokenDetails.socialMinterStoragePath)
        acct.link<&SocialToken.Vault{FungibleToken.Balance, SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
        (tokenDetails.tokenResourcePublicPath, 
        target: tokenDetails.tokenResourceStoragePath)
    }
    execute {
    }
}