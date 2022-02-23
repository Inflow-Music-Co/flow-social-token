transaction(
    contractName: String, 
    code: String,
) {
    prepare(contractAccount: AuthAccount) {
        let existingContract = contractAccount.contracts.get(name: contractName)

        if (existingContract == nil) {
            contractAccount.contracts.add(
                name: contractName, 
                code: code.decodeHex()
            )
        } else {
            contractAccount.contracts.update__experimental(name: contractName, code: code.decodeHex())
        }
    }
}
