// This transaction set pre Allocation Structure, giving rewards to Actor after a specific tokens Minted
//

import FUSD from 0xf8d6e0586b0a20c7
import FungibleToken from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7

transaction(address: Address,initialRewardLimit: UFix64,rewardedTokens: UFix64, milestones: UInt) {
    var tokenReceiver: Capability<&AnyResource{FungibleToken.Receiver}>
    let tokenAdmin: &SocialToken.Administrator
    prepare(signer: AuthAccount) {
       // Create a reference to the admin resource in storage.
        self.tokenAdmin = signer.borrow<&SocialToken.Administrator>(from: SocialToken.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        self.tokenReceiver = getAccount(address)
            .getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)!

        // Create a new minter resource and a private link to a capability for it in the admin's storage.
        self.tokenAdmin.setPreAllocation(address:address, initialRewardLimit: initialRewardLimit, 
        rewardedTokens: rewardedTokens, milestones: milestones, ownerVault: self.tokenReceiver)

    }
}