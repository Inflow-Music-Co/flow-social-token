// This transaction is a template for a transaction that
// could be used by anyone to send tokens to another account
// that has been set up to receive tokens.
//
// The withdraw amount and the account from getAccount
// would be the parameters to the transaction
import FungibleToken from 0xee82856bf20e2aa6
import SocialToken from 0xf8d6e0586b0a20c7

transaction(tokenId: String, amount: UFix64,to:Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {
        let tokenDetails = Controller.getTokenDetails(tokenDetails)
        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&SocialToken.Vault>(from: tokenDetails.tokenResourceStoragePath)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)
    }

    execute {
        let tokenDetails = Controller.getTokenDetails(tokenId)
        let receiverRef =  getAccount(to)
            .getCapability(tokenDetails.tokenResourcePublicPath)
            .borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")

        receiverRef.deposit(from: <-self.sentVault)
        
    }
}