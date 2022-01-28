import SocialToken from 0xe03daebed8ca0615
import FungibleToken from 0x01cf0e2f2f715450
import FUSD from 0x179b6b1cb6755e31

transaction (amountArtistToken: UFix64, amountUsdToken: UFix64){

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
            .getCapability(/public/NMinter)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        let burnedTokens <-  minter.mintTokens("N_0x120e725050340cab",amountArtistToken,fusdPayment:<- self.sentVault)


        let receiverRef =  getAccount(self.trxAddress)
            .getCapability(/public/N_0x8)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        receiverRef.deposit(from: <-burnedTokens)

    log("successfuly deposit the amount in the receiver address")

    }
}
