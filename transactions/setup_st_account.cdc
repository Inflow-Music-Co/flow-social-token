
// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the SocialToken

import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7

transaction {

    prepare(signer: AuthAccount) {

        // Return early if the account already stores a ExampleToken Vault
        if signer.borrow<&SocialToken.Vault>(from: /storage/socialTokenVault) != nil {
            return
        }

        // Create a new ExampleToken Vault and put it in storage
        signer.save(
            <-SocialToken.createEmptyVault(),
            to: /storage/socialTokenVault
        )

        // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
        signer.link<&SocialToken.Vault{FungibleToken.Receiver}>(
            /public/socialTokenReceiver,
            target: /storage/socialTokenVault
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
        signer.link<&SocialToken.Vault{FungibleToken.Balance}>(
            /public/socialTokenBalance,
            target: /storage/socialTokenVault
        )
    }
}