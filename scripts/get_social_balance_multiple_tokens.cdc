import SocialToken from 0xe03daebed8ca0615
import FungibleToken from 0x01cf0e2f2f715450

pub fun main(account: Address): {String: UFix64} {


    let balances : {String: UFix64} = {}
    let acct = getAccount(account)

    let vaultRef1 = acct.getCapability(/public/N_0x8)
        .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    var x =   vaultRef1.getTokenId()

    let vaultRef = acct.getCapability(/public/N_0x8)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    let bal1 = vaultRef.balance;
    balances.insert(key: x, bal1)

    let vaultRef2 = acct.getCapability(/public/S_0x7)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    let vaultRef3 = acct.getCapability(/public/S_0x7)
        .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    var y =   vaultRef3.getTokenId()


    let bal2 = vaultRef2.balance;
    balances.insert(key: y, bal2)

    return balances
}