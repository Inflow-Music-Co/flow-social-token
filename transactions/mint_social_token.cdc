import SocialToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FUSD from 0xf8d6e0586b0a20c7
import Controller from 0xf8d6e0586b0a20c7


transaction (tokenId: String, amountArtistToken: UFix64, amountUsdToken: UFix64){

    let sentVault: @FungibleToken.Vault

    let trxAddress : Address

    prepare(acct: AuthAccount) {

        self.trxAddress = acct.address
        // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&FUSD.Vault>(from:/storage/fusdVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountUsdToken)

        log(self.sentVault.balance)
    }

    execute {
        let minter =  getAccount(self.trxAddress)
            .getCapability(/public/SMinter)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault")
        let burnedTokens <-  minter.mintTokens(tokenId, amountArtistToken, fusdPayment:<- self.sentVault)


        let receiverRef =  getAccount(self.trxAddress)
            .getCapability(Controller.allSocialTokens[tokenId]!.tokenResourcePublicPath)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the S recipient's Vault 2")
        receiverRef.deposit(from: <-burnedTokens)

        log("successfuly deposit the amount in the receiver address")

    }
}
