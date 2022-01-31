import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from "../contracts/SocialToken.cdc"
pub fun main(account: Address): {String: UFix64} {


    let balances : {String: UFix64} = {}
    let acct = getAccount(account)

    let vaultRef1 = acct.getCapability(/public/N_0x6)
        .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    var x =   vaultRef1.getTokenId()

    let vaultRef = acct.getCapability(/public/N_0x6)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    let bal1 = vaultRef.balance;
    balances.insert(key: x, bal1)

    let vaultRef2 = acct.getCapability(/public/S_0x5)
        .borrow<&SocialToken.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    let vaultRef3 = acct.getCapability(/public/S_0x5)
        .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    var y =   vaultRef3.getTokenId()


    let bal2 = vaultRef2.balance;
    balances.insert(key: y, bal2)

    return balances
}
