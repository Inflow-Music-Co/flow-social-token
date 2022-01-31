import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from 0xf8d6e0586b0a20c7
import Controller from 0xf8d6e0586b0a20c7


transaction (tokenId: String, amountArtistToken:UFix64){

    let sentVault: @FungibleToken.Vault
    let accountAddress : Address  

    prepare(acct: AuthAccount) {
        self.accountAddress = acct.address

        // Get a reference to the signer's stored vault
       // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&SocialToken.Vault>(from: Controller.allSocialTokens[tokenId]!.tokenResourceStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")
        log("12313221312")
        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountArtistToken)
    }

    execute {
        let burner =  getAccount(self.accountAddress)
            .getCapability(/public/SBurner)
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
 