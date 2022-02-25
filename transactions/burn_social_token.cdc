import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from 0x01cf0e2f2f715450
import Controller from 0xf8d6e0586b0a20c7
import FiatToken from 0xf8d6e0586b0a20c7


transaction (tokenId: String, amountArtistToken: UFix64){

    let sentVault: @FungibleToken.Vault
    let accountAddress : Address  


    prepare(acct: AuthAccount) {
        let tokenDetails = Controller.getTokenDetails(tokenId)
        self.accountAddress = acct.address

        // Get a reference to the signer's stored vault
       // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&SocialToken.Vault>(from: tokenDetails.tokenResourceStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")
        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountArtistToken)
    }

    execute {
        let tokenDetails = Controller.getTokenDetails(tokenId)
        let burner =  getAccount(self.accountAddress)
            .getCapability(tokenDetails.socialBurnerPublicPath)
            .borrow<&{SocialToken.BurnerPublic}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        let burnedTokens <-  burner.burnTokens(from: <- self.sentVault)
        let userReceiver = getAccount(self.accountAddress)
            .getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&FiatToken.Vault{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")

        userReceiver.deposit(from: <-burnedTokens)
    }
}
