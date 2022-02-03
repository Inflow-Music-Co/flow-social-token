import Controller from "../contracts/Controller.cdc"

transaction(TemplateAdmin: Address) {
    prepare(signer: AuthAccount) {

        // get the public account object for the TemplateAdmin
        let TemplateAdminAccount = getAccount(TemplateAdmin)

        // get the public capability from the TemplateAdmin's public storage
        let TemplateAdminResource = TemplateAdminAccount.getCapability
            <&{Controller.UserSpecialCapability}>
            (/public/UserSpecialCapability)
            .borrow()
            ?? panic("could not borrow reference to UserSpecialCapability")

        // get the private capability from the Authorized owner of the AdminResource
        // - this will be the signer of this transaction
        //
        let specialCapability = signer.getCapability
            <&{Controller.SpecialCapability}>
            (Controller.SpecialCapabilityPrivatePath) 

        // if the special capability is valid...
        if specialCapability.check() {
            // ...add it to the TemplateAdminResource
            TemplateAdminResource.addCapability(cap: specialCapability)
            log("capability added")
        } else {
            // ...let the people know we failed
            panic("special capability is invalid!")
        }
    }
}