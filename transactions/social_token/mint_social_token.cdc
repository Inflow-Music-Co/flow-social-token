import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

transaction(recipient: Address, amount: UFix64) {


    let paymentVault: @FungibleToken.Vault
    let tokenReceiver: &{FungibleToken.Receiver}
    let minterProxy: &SocialToken.MinterProxy
    

    prepare(signer: AuthAccount) {

        //initialise variables
        self.minterProxy = signer
            .borrow<&SocialToken.MinterProxy>(from: SocialToken.MinterProxyStoragePath)
            ?? panic ("could not borrow minter proxy from signer")

        self.tokenReceiver = getAccount(recipient)
            .getCapability(/public/socialTokenReceiver)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")

            let mainFUSDVault = signer.borrow<&FungibleToken.Vault>(from: /storage/fusdVault)
                ?? panic("cannot borrow FUSD vault from account storage")
            
            self.paymentVault <- mainFUSDVault.withdraw(amount: amount)
    }

    execute {
        let mintedVault <- self.minterProxy.mintTokens(amount: amount, fusdPayment: <- self.paymentVault)

        self.tokenReceiver.deposit(from: <- mintedVault)
    }
}