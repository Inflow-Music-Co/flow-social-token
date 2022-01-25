import SocialToken from "../../contracts/SocialToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"

transaction (amountArtistToken:UFix64,amountUsdToken:UFix64, to:Address){

    let sentVault: @FungibleToken.Vault

    prepare(acct: AuthAccount) {

        // Get a reference to the signer's stored vault
        let vaultRef = acct.borrow<&FungibleToken.Vault>(from:/storage/fusdVault)
			?? panic("Could not borrow reference to the owner's Vault!")

        // Withdraw tokens from the signer's stored vault
        self.sentVault <- vaultRef.withdraw(amount: amountUsdToken)

        log(self.sentVault.balance)
    }

    execute {
        let minter =  getAccount(to)
            .getCapability(/public/Minter)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        let x <-  minter.mintTokens("R_0x5",amountArtistToken,fusdPayment:<- self.sentVault)


    let receiverRef =  getAccount(to)
            .getCapability(/public/R_0x5)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        receiverRef.deposit(from: <-x)

    log("successfuly deposit the amount in the receiver address")

    }
}
