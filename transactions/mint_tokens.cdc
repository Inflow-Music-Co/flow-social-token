import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7

transaction(recipient: Address, amount: UFix64) {

    let minterProxy: &SocialToken.MinterProxy
    let tokenReceiver: &{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {

        //initialise variables
        self.minterProxy = signer
            .borrow<&SocialToken.MinterProxy>(from: SocialToken.MinterProxyStoragePath)
            ?? panic ("could not borrow minter proxy from signer")

        self.tokenReceiver = getAccount(recipient)
            .getCapability(/public/socialTokenReceiver)!
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Unable to borrow receiver reference")

    }

    execute {
        let mintedVault <- self.minterProxy.mintTokens(amount: amount)

        self.tokenReceiver.deposit(from: <- mintedVault)
    }
}