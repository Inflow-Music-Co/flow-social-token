import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"
import Controller from "../contracts/Controller.cdc"
import FUSD from "../contracts/FUSD.cdc"


transaction (symbol: String, maxSupply: UFix64, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminResourceStoragePath)
            ??panic("could not borrow a reference to the admin")

            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
            acct.address: Controller.FeeStructure(0.03),
            artistAddress: Controller.FeeStructure(0.07)
            }
        adminResource.registerToken(symbol, maxSupply, feeSplitterDetail,artistAddress)
        log("token registered")
    }  
}