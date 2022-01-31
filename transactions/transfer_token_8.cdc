// This transaction is a template for a transaction that
// could be used by anyone to send tokens to another account
// that has been set up to receive tokens.
//
// The withdraw amount and the account from getAccount
// would be the parameters to the transaction
import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"



transaction(amount: UFix64,to:Address) {

    // The Vault resource that holds the tokens that are being transferred
    let sentVault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = signer.borrow<&SocialToken.Vault>(from: /storage/N_0x6)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amount)

        log(self.sentVault.balance)


    }

    execute {


        // Get a reference to the recipient's Receiver
        let receiverRef =  getAccount(to)
            .getCapability(/public/N_0x6)
            .borrow<&{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault")
//
        log(receiverRef)
        log("reached")
    //    // Deposit the withdrawn tokens in the recipient's receiver
        receiverRef.deposit(from: <-self.sentVault)
        log("succesfuly deposited")
        
    }
}