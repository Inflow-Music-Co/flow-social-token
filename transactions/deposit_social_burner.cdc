// This transaction creates a new SocialToken burner and deposits
// it into an existing burner proxy resource on the specified account.
//
// Parameters:
// - burnerAddress: The burner account address.
//
// This transaction will fail if the authorizer does not have the SocialToken.Administrator
// resource.
//
// This transaction will fail if the burner account does not have
// an SocialToken.BurnerProxy resource. Use the setup_st_burner.cdc transaction to
// create a burner proxy in the burner account.

import SocialToken from 0xf8d6e0586b0a20c7

transaction(burnerAddress: Address) {

    let resourceStoragePath: StoragePath
    let capabilityPrivatePath: CapabilityPath
    let burnerCapability: Capability<&SocialToken.Burner>

    prepare(adminAccount: AuthAccount) {

        // These paths must be unique within the SocialToken contract account's storage
        self.resourceStoragePath = /storage/socialTokenAdminBurner
        self.capabilityPrivatePath = /private/socialTokenAdminBurner

        // Create a reference to the admin resource in storage.
        let tokenAdmin = adminAccount.borrow<&SocialToken.Administrator>(from: SocialToken.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        // Create a new burner resource and a private link to a capability for it in the admin's storage.
        let burner <- tokenAdmin.createNewBurner(pool: SocialToken.AdminPool)
        
        adminAccount.save(<- burner, to: self.resourceStoragePath)
        
        self.burnerCapability = adminAccount.link<&SocialToken.Burner>(
            self.capabilityPrivatePath,
            target: self.resourceStoragePath
        ) ?? panic("Could not link burner")
    }

    execute {
        // This is the account that the capability will be given to
        let burnerAccount = getAccount(burnerAddress)

        let capabilityReceiver = burnerAccount.getCapability
            <&SocialToken.BurnerProxy{SocialToken.BurnerProxyPublic}>
            (SocialToken.BurnerProxyPublicPath)!
            .borrow() ?? panic("Could not borrow capability receiver reference")

        capabilityReceiver.setBurnerCapability(cap: self.burnerCapability)
    }

}