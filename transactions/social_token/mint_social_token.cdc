import SocialToken from "../../contracts/SocialToken.cdc"
import FungibleToken from "../../contracts/FungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"

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
            .getCapability(/public/Minter)
            .borrow<&{SocialToken.MinterPublic}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        let x <-  minter.mintTokens("S_0x5",amountArtistToken,fusdPayment:<- self.sentVault)


        let receiverRef =  getAccount(self.trxAddress)
            .getCapability(/public/S_0x5)
            .borrow<&SocialToken.Vault{FungibleToken.Receiver}>()
			?? panic("Could not borrow receiver reference to the recipient's Vault 2")
        receiverRef.deposit(from: <-x)

    log("successfuly deposit the amount in the receiver address")

    }
}
