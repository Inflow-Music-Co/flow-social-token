// This transaction creates a new burner proxy resource and
// stores it in the signer's account.
//
// After running this transaction, the Social Token administrator
// must run deposit_st_burner.cdc to deposit a burner resource
// inside the burner proxy.

import SocialToken from 0xf8d6e0586b0a20c7

transaction {
    prepare(burner: AuthAccount) {

        let burnerProxy <- SocialToken.createBurnerProxy()

        burner.save(<- burnerProxy, to: SocialToken.BurnerProxyStoragePath)

        burner.link<&SocialToken.BurnerProxy{SocialToken.BurnerProxyPublic}>(
            SocialToken.BurnerProxyPublicPath,
            target: SocialToken.BurnerProxyStoragePath
        )
    }
}