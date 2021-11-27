// This transaction creates a new minter proxy resource and
// stores it in the signer's account.
//
// After running this transaction, the Social Token administrator
// must run deposit_st_minter.cdc to deposit a minter resource
// inside the minter proxy.

import SocialToken from 0xf8d6e0586b0a20c7

transaction {
    prepare(minter: AuthAccount) {

        let minterProxy <- SocialToken.createMinterProxy()

        minter.save(<- minterProxy, to: SocialToken.MinterProxyStoragePath)

        minter.link<&SocialToken.MinterProxy{SocialToken.MinterProxyPublic}>(
            SocialToken.MinterProxyPublicPath,
            target: SocialToken.MinterProxyStoragePath
        )
    }
}
