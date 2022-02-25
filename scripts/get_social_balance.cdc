import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from 0x1cf0e2f2f715450
import Controller from 0xf8d6e0586b0a20c7

pub fun main(address:Address,tokenId: String): UFix64 {
    let acct = getAccount(address)
    let tokenDetails = Controller.getTokenDetails(tokenId)
    let vaultRef = acct.getCapability(tokenDetails.tokenResourcePublicPath)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}