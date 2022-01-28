import SocialToken from 0xe03daebed8ca0615
import FungibleToken from 0x01cf0e2f2f715450

transaction (amountArtistToken:UFix64){

    let sentVault: @FungibleToken.Vault
    let accountAddress : Address  

    prepare(acct: AuthAccount) {
        self.accountAddress = acct.address

        // Get a reference to the signer's stored vault
       // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&SocialToken.Vault>(from: /storage/S_0x5)
			?? panic("Could not borrow reference to the owner's Vault!")

            

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountArtistToken)


        let publicVault = getAccount(self.accountAddress).getCapability(/public/S_0x5)
                            .borrow<&SocialToken.Vault{SocialToken.SocialTokenPublic}>()
                            ??panic("could not get account capability")
            log(publicVault.getTokenId())
    
    }

    execute {
        let burner =  getAccount(self.accountAddress)
            .getCapability(/public/RBurner)
            .borrow<&{SocialToken.BurnerPublic}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        let burnedTokens <-  burner.burnTokens(from: <- self.sentVault)
        let userReceiver = getAccount(self.accountAddress)
            .getCapability(/public/fusdReceiver)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")

        userReceiver.deposit(from: <-burnedTokens)
    

    log("successfuly destroyed the amount of the receiver address")

    }
}

 