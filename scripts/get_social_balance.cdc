import SocialToken from "../contracts/SocialToken.cdc"
import FungibleToken from "../contracts/FungibleToken.cdc"


pub fun main(account:Address):UFix64{
    let publicVault = getAccount(account).getCapability(/public/K_0x5)
                                .borrow<&FungibleToken.Vault{FungibleToken.Balance}>()
                                ??panic("could not get account capability")

    return publicVault.balance
}