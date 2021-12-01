import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

transaction(amount: UFix64) {

    let burner: &SocialToken.BurnerProxy
    let tokenReceiver: &{FungibleToken.Receiver}
    let vault: @FungibleToken.Vault

    prepare(signer: AuthAccount) {

        //initialise variables
        self.vault <- signer.borrow<&SocialToken.Vault>(from: /storage/socialTokenVault)!
            .withdraw(amount: amount)

        self.tokenReceiver = signer
            .getCapability(/public/fusdReceiver)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow FUSD receiver reference")

        self.burner = signer
            .borrow<&SocialToken.BurnerProxy>(from: SocialToken.BurnerProxyStoragePath)
            ?? panic ("could not borrow minter proxy from signer")
    }

    execute {
        let fusdAfterBurnVault <- self.burner.burnTokens(from: <- self.vault)
        self.tokenReceiver.deposit(from: <- fusdAfterBurnVault)
    }
}