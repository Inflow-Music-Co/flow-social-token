import SocialToken from "../contracts/SocialToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(/public/S_0x5)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}