// This transaction creates a fee structure and
// us this structure while miniting for distribution.
import FungibleToken from "../../contracts/FungibleToken.cdc"
import SocialToken from "../../contracts/SocialToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"


transaction(receiverAddress: Address, percentage: UFix64) {

    var fusdReceiver: Capability<&AnyResource{FungibleToken.Receiver}>
    let tokenAdmin: &SocialToken.Administrator
    let distributionPercentage: {String:AnyStruct} 

    prepare(signer: AuthAccount) {

        //initialise variables
        self.tokenAdmin = signer.borrow<&SocialToken.Administrator>(from: SocialToken.AdminStoragePath)
            ?? panic("Could not borrow a reference to the admin resource")

        self.distributionPercentage = {"percentage":percentage}

        self.fusdReceiver = getAccount(receiverAddress)
            .getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)!

    }

    execute {
        self.tokenAdmin.setFeeStructure(address:receiverAddress,value:self.distributionPercentage,ownerVault: self.fusdReceiver)

    }
}
