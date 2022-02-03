import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"
import FUSD from "../contracts/FUSD.cdc"


transaction (amountArtistToken: UFix64, amountUsdToken: UFix64){

    let sentVault: @FungibleToken.Vault

    let trxAddress : Address
    let fusdReceiver: Capability<&AnyResource{FungibleToken.Receiver}>

    prepare(acct: AuthAccount) {
        self.trxAddress = acct.address
        // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&FUSD.Vault>(from:/storage/fusdVault)
			?? panic("Could not borrow reference to the owner's Vault!")
        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountUsdToken)
        self.fusdReceiver = getAccount(acct.address)
            .getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

    }

    execute {
        let minter =  getAccount(self.trxAddress)
            .getCapability(/public/NMinter)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault")
        let mintedTokens <-  minter.mintTokens("N_0x120e725050340cab",amountArtistToken,fusdPayment:<- self.sentVault, receiverVault: self.fusdReceiver)

        let receiverRef =  getAccount(self.trxAddress)
            .getCapability(/public/N_0x6)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault 2")
        receiverRef.deposit(from: <-mintedTokens)

    }
}
