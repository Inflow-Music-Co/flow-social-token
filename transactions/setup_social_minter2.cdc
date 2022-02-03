// This transaction creates a new minter proxy resource and
// stores it in the signer's account.
//
// After running this transaction, the Social Token administrator
// must run deposit_st_minter.cdc to deposit a minter resource
// inside the minter proxy.

import SocialToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7

transaction (tokenId: String) {

  prepare(acct: AuthAccount) {

    acct.save(<- SocialToken.createEmptyVault(), to: Controller.allSocialTokens[tokenId]!.tokenResourceStoragePath)
    acct.save(<- SocialToken.createNewMinter(), to: /storage/NMinter)
    acct.save(<- SocialToken.createNewBurner(), to: /storage/NBurner)
    acct.link<&SocialToken.Burner{SocialToken.BurnerPublic}>(/public/NBurner, target: /storage/NBurner)
    acct.link<& SocialToken.Minter{SocialToken.MinterPublic}>(/public/NMinter, target:  /storage/NMinter)
    acct.link<&SocialToken.Vault{FungibleToken.Balance, SocialToken.SocialTokenPublic, FungibleToken.Receiver}>
    (Controller.allSocialTokens[tokenId]!.tokenResourcePublicPath, 
    target: Controller.allSocialTokens[tokenId]!.tokenResourceStoragePath)
  }

  execute {
 
  log("done")
  }
}
