import SocialToken from 0xe03daebed8ca0615
import FungibleToken from 0x01cf0e2f2f715450

pub fun main(account: Address): UFix64 {
    let acct = getAccount(account)
    let vaultRef = acct.getCapability(/public/N_0x8)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}