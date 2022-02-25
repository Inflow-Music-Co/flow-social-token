// MinterController uses this to configure minter allowance 
// It succeeds of MinterController has assigned Minter from MasterMinter

import FiatToken from 0xf8d6e0586b0a20c7

transaction (amount: UFix64) {
    prepare(minterController: AuthAccount) {
        let mc = minterController.borrow<&FiatToken.MinterController>(from: FiatToken.MinterControllerStoragePath)
            ?? panic ("no minter controller resource avaialble");

        mc.configureMinterAllowance(allowance: amount);
    }
}