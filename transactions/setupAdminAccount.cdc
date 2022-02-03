import Controller from "../contracts/Controller.cdc"

transaction() {
    prepare(signer: AuthAccount) {

        let adminResouce <- Controller.createSocialTokenResource()
        // save the resource to the signer's account storage
        signer.save(<- adminResouce, to: Controller.SocialTokenResourceStoragePath)

        signer.link<&{Controller.UserSpecialCapability}>(
            /public/UserSpecialCapability,
            target: Controller.SocialTokenResourceStoragePath
        )
        // link the UnlockedCapability in private storage
        signer.link<&{Controller.SocialTokenResourcePublic}>(
            /private/SocialTokenResourcePrivatePath,
            target: Controller.SocialTokenResourceStoragePath
        )
    }
    execute{
    
    }
    
}