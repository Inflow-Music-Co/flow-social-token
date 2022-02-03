
import SocialToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FUSD from 0xf8d6e0586b0a20c7
import Controller from 0xf8d6e0586b0a20c7


transaction (tokenId: String, amountArtistToken: UFix64, amountUsdToken: UFix64){

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
        let tokenDetails = Controller.getTokenDetails(tokenId)
        let minter =  getAccount(self.trxAddress)
            .getCapability(tokenDetails.socialMinterPublicPath)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault")
        let mintedTokens <-  minter.mintTokens(tokenDetails.tokenId,amountArtistToken,fusdPayment:<- self.sentVault, receiverVault: self.fusdReceiver)

        let receiverRef =  getAccount(self.trxAddress)
            .getCapability(tokenDetails.tokenResourcePublicPath)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault 2")
        receiverRef.deposit(from: <-mintedTokens)

    }
}
