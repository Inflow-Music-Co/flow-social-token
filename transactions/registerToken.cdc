import FungibleToken from "../contracts/FungibleToken.cdc"
import SocialToken from "../contracts/SocialToken.cdc"
import Controller from "../contracts/Controller.cdc"
import FUSD from "../contracts/FUSD.cdc"


transaction (symbol: String, maxSupply: UFix64, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminResourceStoragePath)
            ??panic("could not borrow a reference to the admin")

            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
            acct.address: Controller.FeeStructure(0.05),
            artistAddress: Controller.FeeStructure(0.15)
            }
        
        let tokenStoragePath = /storage/TestSymbol_0x05
        let tokenPublicPath = /public/TestSymbol_0x05
        adminResource.registerToken(symbol, maxSupply, feeSplitterDetail, artistAddress, tokenStoragePath:tokenStoragePath,tokenPublicPath:tokenPublicPath)
        log("token registered")
    }  
}