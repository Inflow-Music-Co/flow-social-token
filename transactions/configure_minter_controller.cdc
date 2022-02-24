// Masterminter uses this to configure which Minter the MinterController manages

import FiatToken from 0xf8d6e0586b0a20c7

transaction (minter: UInt64, minterController: UInt64) {
    prepare(masterMinter: AuthAccount) {
        let mm = masterMinter.borrow<&FiatToken.MasterMinterExecutor>(from: FiatToken.MasterMinterExecutorStoragePath) 
            ?? panic ("no masterminter resource avaialble");

        mm.configureMinterController(minter: minter, minterController: minterController);
    }
    post {
        FiatToken.getManagedMinter(resourceId: minterController) == minter : "minterController not configured"
    }
}