import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"

pub fun main(account: Address): String {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(/public/N_0x8)
        .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.getTokenId()
}