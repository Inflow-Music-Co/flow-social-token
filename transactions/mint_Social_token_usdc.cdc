import SocialToken from 0x01cf0e2f2f715450
import FungibleToken from 0xee82856bf20e2aa6
import FiatToken from 0xf8d6e0586b0a20c7
import Controller from 0xf8d6e0586b0a20c7

transaction(tokenId: String, amountArtistToken: UFix64, amountUsdToken: UFix64) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault
    
    let trxAddress : Address
    let usdcReceiver: Capability<&AnyResource{FungibleToken.Receiver}>


    prepare(acct: AuthAccount) {

        self.trxAddress = acct.address
        
        let vaultRef = acct.borrow<&FiatToken.Vault>(from: FiatToken.VaultStoragePath)
            ?? panic("Could not borrow reference to the owner's Vault!")
            
        self.sentVault <- vaultRef.withdraw(amount: amountUsdToken)
         self.usdcReceiver = getAccount(acct.address)
            .getCapability<&{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
    }

    execute {

        let tokenDetails = Controller.getTokenDetails(tokenId)
         let minter =  getAccount(self.trxAddress)
            .getCapability(tokenDetails.socialMinterPublicPath)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault")
        let mintedTokens <-  minter.mintTokens(tokenDetails.tokenId, amountArtistToken, usdcPayment: <- self.sentVault, receiverVault: self.usdcReceiver)
       
       let receiverRef =  getAccount(self.trxAddress)
            .getCapability(tokenDetails.tokenResourcePublicPath)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault 2")

        receiverRef.deposit(from: <-mintedTokens)
    }
}