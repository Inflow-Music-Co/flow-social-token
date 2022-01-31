import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from 0xf8d6e0586b0a20c7
import Controller from 0xf8d6e0586b0a20c7

pub fun main(address:Address,token: String): UFix64 {
    let acct = getAccount(address)
    let vaultRef = acct.getCapability(Controller.allSocialTokens[token]!.tokenResourcePublicPath)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}