
  
// This script mints token on FiatToken contract and deposits the minted amount to the receiver's Vault 
// It will fail if minter does not have enough allowance, is blocklisted or contract is paused

import FungibleToken from 0xee82856bf20e2aa6
import FiatToken from 0xf8d6e0586b0a20c7

transaction (amount: UFix64, receiver: Address) {
    let mintedVault: @FungibleToken.Vault;

    prepare(minter: AuthAccount) {
        let m = minter.borrow<&FiatToken.Minter>(from: FiatToken.MinterStoragePath) 
            ?? panic ("no minter resource avaialble");
        self.mintedVault <- m.mint(amount: amount)
    }

    execute {
        let recvAcct = getAccount(receiver);
        let receiverRef = recvAcct.getCapability(FiatToken.VaultReceiverPubPath)
            .borrow<&{FungibleToken.Receiver}>()
            ?? panic("Could not borrow receiver reference to the recipient's Vault")

        receiverRef.deposit(from: <-self.mintedVault)
    }
}