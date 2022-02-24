import Controller from 0xf8d6e0586b0a20c7

transaction (tokenId: String, artistAddress: Address){
    prepare(acct: AuthAccount) {
        let adminResource = acct.borrow<&Controller.Admin>(from:Controller.AdminStoragePath)
            ??panic("could not borrow a reference to the admin")

            let feeSplitterDetail: {Address:Controller.FeeStructure} = {
            acct.address: Controller.FeeStructure(0.05),
            artistAddress: Controller.FeeStructure(0.15)
            }
        
        
        adminResource.updateFeeSpliterDetail(tokenId, feeSplitterDetail)
    }  
}