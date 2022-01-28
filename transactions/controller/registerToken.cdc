import FungibleToken from 0x01cf0e2f2f715450
import Controller from 0xf3fcd2c1a78f5eee
import FUSD from 0x179b6b1cb6755e31
import SocialToken from 0xe03daebed8ca0615


transaction (maxSupply: UFix64, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminResourceStoragePath)
            ??panic("could not borrow a reference to the admin")

            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
            acct.address: Controller.FeeStructure(0.03),
            artistAddress: Controller.FeeStructure(0.07)
            }
            let symbol = "N"

        adminResource.registerToken(symbol, maxSupply, feeSplitterDetail,artistAddress)
        log("token registered")
    }  
}