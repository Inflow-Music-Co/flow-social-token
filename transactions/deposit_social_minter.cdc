// This transaction creates a new SocialToken minter and deposits
// it into an existing minter proxy resource on the specified account.
//
// Parameters:
// - minterAddress: The minter account address.
//
// This transaction will fail if the authorizer does not have the SocialToken.Administrator
// resource.
//
// This transaction will fail if the minter account does not have
// an SocialToken.MinterProxy resource. Use the setup_st_minter.cdc transaction to
// create a minter proxy in the minter account.

import SocialToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import FUSD from 0xf8d6e0586b0a20c7

transaction(minterAddress: Address) {

    let resourceStoragePath: StoragePath
    let capabilityPrivatePath: CapabilityPath
    let minterCapability: Capability<&SocialToken.Minter>


    prepare(adminAccount: AuthAccount) {

        // These paths must be unique within the SocialToken contract account's storage
        self.resourceStoragePath = /storage/socialTokenAdminMinter
        self.capabilityPrivatePath = /private/socialTokenAdminMinter

        // Create a reference to the admin resource in storage.
        let tokenAdmin = adminAccount.borrow<&SocialToken.Administrator>(from: SocialToken.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        // Create a new minter resource and a private link to a capability for it in the admin's storage.
        // use FUSDPool Constructor to initialise FUSD Pool with admin FUSD Reciever
        let minter <- tokenAdmin.createNewMinter(pool: SocialToken.AdminPool)
        
        adminAccount.save(<- minter, to: self.resourceStoragePath)
        
        self.minterCapability = adminAccount.link<&SocialToken.Minter>(
            self.capabilityPrivatePath,
            target: self.resourceStoragePath
        ) ?? panic("Could not link minter")
    }

    execute {
        // This is the account that the capability will be given to
        let minterAccount = getAccount(minterAddress)

        let capabilityReceiver = minterAccount.getCapability
            <&SocialToken.MinterProxy{SocialToken.MinterProxyPublic}>
            (SocialToken.MinterProxyPublicPath)!
            .borrow() ?? panic("Could not borrow capability receiver reference")

        capabilityReceiver.setMinterCapability(cap: self.minterCapability)
    }

}