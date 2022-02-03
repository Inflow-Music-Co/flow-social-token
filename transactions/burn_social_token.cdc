import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"



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

    }
}
