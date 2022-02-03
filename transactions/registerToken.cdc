import Controller from "../contracts/Controller.cdc"

transaction (symbol: String, maxSupply: UFix64, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminStoragePath)
            ??panic("could not borrow a reference to the admin")
            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
            acct.address: Controller.FeeStructure(0.03),
            artistAddress: Controller.FeeStructure(0.07)
            }
        adminResource.registerToken(symbol, maxSupply, feeSplitterDetail,artistAddress)
    }  
}