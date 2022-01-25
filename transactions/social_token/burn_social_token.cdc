import SocialToken from "../../contracts/SocialToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction (amountArtistToken:UFix64){

    let sentVault: @FungibleToken.Vault
    let accountAddress : Address  

    prepare(acct: AuthAccount) {
        self.accountAddress = acct.address

        // Get a reference to the signer's stored vault
       // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&SocialToken.Vault>(from: /storage/K_0x5)
			?? panic("Could not borrow reference to the owner's Vault!")

            

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountArtistToken)


        let publicVault = getAccount(self.accountAddress).getCapability(/public/R_0x5)
                                    .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
                                    ??panic("could not get account capability")
            log(publicVault.getTokenId())
    }

    execute {
        let burner =  getAccount(self.accountAddress)
            .getCapability(/public/Burner)
            .borrow<&{SocialToken.BurnerPublic}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        let x =  burner.burnTokens(from: <- self.sentVault)
    }
}
