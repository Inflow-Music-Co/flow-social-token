import FUSD from 0xf8d6e0586b0a20c7
import SocialToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7

transaction (symbol: String, maxSupply: UFix64, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminStoragePath)
            ??panic("could not borrow a reference to the admin")

            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
                acct.address: Controller.FeeStructure(0.05),
                artistAddress: Controller.FeeStructure(0.15)
            }
            
        let tokenStoragePath = /storage/InflowSymbol_0x05
        let tokenPublicPath = /public/InflowSymbol_0x05
        let socialMinterStoragePath = /storage/InflowSymbol_0x5Minter
        let socialMinterPublicPath = /public/InflowSymbol_0x5Minter
        let socialBurnerStoragePath = /storage/InflowSymbol_0x5Burner
        let socialBurnerPublicPath = /public/InflowSymbol_0x5Burner
        adminResource.registerToken(symbol, maxSupply, feeSplitterDetail, artistAddress,
            tokenStoragePath, tokenPublicPath,
            socialMinterStoragePath, socialMinterPublicPath,
            socialBurnerStoragePath, socialBurnerPublicPath
            )
    }  
}