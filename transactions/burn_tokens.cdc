import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7

transaction(amount: UFix64) {

    let burner: &SocialToken.BurnerProxy
    let vault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        //initialise variables
        self.vault <- signer.borrow<&SocialToken.Vault>(from: /storage/socialTokenVault)!
            .withdraw(amount: amount)

        self.burner = signer
            .borrow<&SocialToken.BurnerProxy>(from: SocialToken.BurnerProxyStoragePath)
            ?? panic ("could not borrow minter proxy from signer")
    }

    execute {
        self.burner.burnTokens(from: <- self.vault)
    }
}