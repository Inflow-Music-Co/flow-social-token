import FUSD from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7

transaction (symbol: String, maxSupply: UFix64, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminResourceStoragePath)
            ??panic("could not borrow a reference to the admin")

            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
            acct.address: Controller.FeeStructure(0.05),
            artistAddress: Controller.FeeStructure(0.15)
            }
        
        let tokenStoragePath = /storage/Test2Symbol_0x03
        let tokenPublicPath = /public/Test2Symbol_0x03
        adminResource.registerToken(symbol, maxSupply, feeSplitterDetail, artistAddress, tokenStoragePath:tokenStoragePath,tokenPublicPath:tokenPublicPath)
        log("token registered")
    }  
}