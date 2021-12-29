import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

transaction(socialTokenAmount: UFix64, fusdPayment: UFix64) {


    let paymentVault: @FungibleToken.Vault
    let tokenReceiver: &{FungibleToken.Receiver}
    let minterProxy: &SocialToken.MinterProxy
    let fusdReceiver: Capability<&AnyResource{FungibleToken.Receiver}>

    prepare(signer: AuthAccount) {

        //initialise variables
        self.minterProxy = signer
            .borrow<&SocialToken.MinterProxy>(from: SocialToken.MinterProxyStoragePath)
            ?? panic ("could not borrow minter proxy from signer")

        self.tokenReceiver = signer
            .getCapability(/public/socialTokenReceiver)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow Social Token receiver reference")

        let fusdVault = signer.borrow<&FungibleToken.Vault>(from: /storage/fusdVault)
            ?? panic("cannot borrow FUSD vault from account storage")
        
        self.paymentVault <- fusdVault.withdraw(amount: fusdPayment)

        self.fusdReceiver = getAccount(signer.address)
            .getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)!
    }

    execute {
        let mintedVault <- self.minterProxy.mintTokens(amount: socialTokenAmount, fusdPayment: <- self.paymentVault, receiverVault: self.fusdReceiver)
        self.tokenReceiver.deposit(from: <- mintedVault)

        // @TODO handle if not enough FUSD
    }
}