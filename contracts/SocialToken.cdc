import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

pub contract SocialToken : FungibleToken{

    // Total supply of all social tokens that are minted using this contract
    pub var totalSupply:UFix64

    // Events
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokensMinted(_ tokenId: String, _ mintPrice: UFix64, _ amount: UFix64)
    pub event TokensBurned(_ tokenId: String, _ burnPrice: UFix64, _ amount: UFix64)

    // a variable that store admin capability to utilize methods of controller contract
    access(contract) let adminRef : Capability<&{Controller.SocialTokenResourcePublic}>
    // a variable which will store the structure of FUSDPool
    pub var collateralPool: FUSDPool

    pub resource interface SocialTokenPublic{
        pub fun getTokenId():String 
    }
    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    pub resource Vault : SocialTokenPublic, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        pub var balance: UFix64
        pub var tokenId: String


        init(balance: UFix64){
            self.balance = balance
            self.tokenId = ""

        }
        pub fun setTokenId(_ tokenId: String){
            pre{
                tokenId !=nil: "token id must not be null"
            }
            self.tokenId = tokenId
        }
        pub fun getTokenId(): String{
            return self.tokenId
        }
        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from : @FungibleToken.Vault){
            let vault <- from as! @SocialToken.Vault
            if(self.tokenId == ""){
                self.tokenId = vault.tokenId 
            }
            assert(vault.tokenId == self.tokenId, message:"error: invalid token id") 
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }
        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            let vault <- create Vault(balance:amount)
            vault.setTokenId(self.tokenId)
            emit TokensWithdrawn(amount:amount, from: self.owner!.address)
            return <- vault
        }
        destroy () {
            SocialToken.totalSupply = SocialToken.totalSupply - self.balance
        }
    }
    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @Vault{
        return <- create Vault(balance:0.0)
    }
    // createNewMinter
    //
    // Function that creates a new minter
    // and returns it to the calling context. A user must call this function
    // and store the returned Minter in their storage in order to allow their
    // account to be able to mint new tokens.
    //
    pub fun createNewMinter():@Minter{
        return <- create Minter()
    }
    // createNewBurner
    //
    // Function that creates a new burner
    // and returns it to the calling context. A user must call this function
    // and store the returned Burner in their storage in order to allow their
    // account to be able to burn tokens.
    //
    pub fun createNewBurner():@Burner{
        return <- create Burner()
    }
    // A structure that contains all the data related to the FUSDPool
    pub struct FUSDPool {
        pub let receiver: Capability<&{FungibleToken.Receiver}>
        pub let provider: Capability<&{FungibleToken.Provider}>
        pub let balance : Capability<&{FungibleToken.Balance}>

        init(
            _receiver: Capability<&{FungibleToken.Receiver}>, 
            _provider: Capability<&{FungibleToken.Provider}>,
            _balance : Capability<&{FungibleToken.Balance}>
            ) {
            self.receiver = _receiver
            self.provider = _provider
            self.balance = _balance
        }
    }

    access(contract) fun distributeFee(_ tokenId : String, _ fusdPayment: @FungibleToken.Vault): @FungibleToken.Vault{
        let amount = fusdPayment.balance
        let tokenDetails = Controller.getTokenDetails(tokenId)
        for address in tokenDetails.feeSplitterDetail.keys {
            let feeStructer = tokenDetails.feeSplitterDetail[address]
            let tempAmmount = amount * feeStructer!.percentage
            let tempraryVault <- fusdPayment.withdraw(amount:tempAmmount)
            let account = getAccount(address)
            let depositSigner= account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
            .borrow()
            ??panic("could not borrow reference to the receiver")
            depositSigner.deposit(from:<- tempraryVault)
        }
        return <- fusdPayment
    }
    pub fun getMintPrice(_ tokenId: String, _ amount: UFix64): UFix64 {
        pre { 
            amount > 0.0: "Amount must be greator than zero"
            tokenId != "" : "token id must not be null"
            Controller.getTokenDetails(tokenId).tokenId !=nil: "token not registered"
        }
        let tokenDetails = Controller.getTokenDetails(tokenId)
        let supply = tokenDetails.issuedSupply
        let newSupply = supply + amount
        let reserve = tokenDetails.reserve
        if supply == 0.0 {
            return (tokenDetails.slope.saturatingMultiply((amount.saturatingMultiply(amount)))/2.0/10000.0) 
        } else {
            var totalNewSupply = newSupply.saturatingMultiply(newSupply)
            return (((reserve.saturatingMultiply(totalNewSupply) / supply.saturatingMultiply(supply))) - reserve)
        }
    }  
    pub fun getBurnPrice(_ tokenId: String, _ amount: UFix64): UFix64{
        pre { 
            amount > 0.0: "Amount must be greator than zero"
            Controller.getTokenDetails(tokenId).tokenId !=nil: "token not registered"
        }
        let tokenDetails = Controller.getTokenDetails(tokenId)
        assert(tokenDetails.tokenId != "", message:"token id must not be null")
        let supply = tokenDetails.issuedSupply
        assert((supply > 0.0), message: "Token supply is zero")
        assert((supply>=amount), message: "amount greater than supply")
        let newSupply = supply - amount
        var _reserve = tokenDetails.reserve
        let totalNewSupply = newSupply.saturatingMultiply(newSupply)
        return (_reserve - ((_reserve.saturatingMultiply(totalNewSupply)) / (supply.saturatingMultiply(supply))))
    }
    
    pub resource interface MinterPublic{
        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @FungibleToken.Vault,receiverVault: Capability<&AnyResource{FungibleToken.Receiver}>): @SocialToken.Vault
    }

    pub resource Minter:MinterPublic {

        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @FungibleToken.Vault, receiverVault: Capability<&AnyResource{FungibleToken.Receiver}>): @SocialToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                Controller.getTokenDetails(tokenId).tokenId !=nil: "toke not registered"
                amount + Controller.getTokenDetails(tokenId).issuedSupply <= Controller.getTokenDetails(tokenId).maxSupply : "Max supply reached"
                SocialToken.adminRef.borrow() !=nil: "social token does not have controller capability"
            }
            var remainingFUSD = 0.0
            var remainingSocialToken = 0.0
            let mintPrice = SocialToken.getMintPrice(tokenId, amount)

            assert(fusdPayment.balance >= mintPrice, message: "You don't have sufficient balance to mint tokens")
            var totalPayment = fusdPayment.balance
            assert(totalPayment>=mintPrice, message: "No payment yet")
            let extraAmount = totalPayment-mintPrice
            if(extraAmount > 0.0){
                //Create Vault of extra amount and deposit back to user
                totalPayment=totalPayment-extraAmount
                let remainingAmountVault <- fusdPayment.withdraw(amount: extraAmount)
                let remainingVault = receiverVault.borrow()!
                remainingVault.deposit(from: <- remainingAmountVault)
            }
            let tempraryVar <- create SocialToken.Vault(balance: amount)
            tempraryVar.setTokenId(tokenId)
            let tokenDetails = Controller.getTokenDetails(tokenId)
            SocialToken.adminRef.borrow()!.incrementIssuedSupply(tokenId, amount)
            let remainingAmount <- SocialToken.distributeFee(tokenId, <- fusdPayment)
            SocialToken.totalSupply = SocialToken.totalSupply + amount
            SocialToken.adminRef.borrow()!.incrementReserve(tokenId, remainingAmount.balance)
            SocialToken.collateralPool.receiver.borrow()!.deposit(from:<- remainingAmount)
            emit TokensMinted(tokenId,mintPrice, amount)
            return <- tempraryVar
            }
    }
    pub resource interface BurnerPublic{
        pub fun burnTokens(from: @FungibleToken.Vault) : @FungibleToken.Vault
    }
    pub resource Burner : BurnerPublic {
        pub fun burnTokens( from: @FungibleToken.Vault): @FungibleToken.Vault{
            let vault <- from as! @SocialToken.Vault
            let amount = vault.balance
            let tokenId = vault.getTokenId()
            let burnPrice = SocialToken.getBurnPrice(tokenId, amount)
            let tokenDetails = Controller.getTokenDetails(tokenId)
            SocialToken.adminRef.borrow()!.decrementIssuedSupply(tokenId, amount)
            SocialToken.adminRef.borrow()!.decrementReserve(tokenId, burnPrice)
            emit TokensBurned(tokenId, burnPrice, amount)
            destroy vault
            return <- SocialToken.collateralPool.provider.borrow()!.withdraw(amount:burnPrice)
        }
    }

    init(){
        self.totalSupply = 0.0

        var adminPrivateCap = self.account.getCapability
            <&{Controller.SocialTokenResourcePublic}>(/private/SocialTokenResourcePrivatePath)
        
        self.adminRef = adminPrivateCap
        
        let vault <-FUSD.createEmptyVault()
        self.account.save(<-vault, to:/storage/fusdVault)
        
        self.account.link<&FUSD.Vault{FungibleToken.Receiver}>(
            /public/fusdReceiver,
            target: /storage/fusdVault
        )
        
        self.account.link<&FUSD.Vault{FungibleToken.Balance}>(
            /public/fusdBalance,
            target: /storage/fusdVault
        )
        
        self.account.link<&FUSD.Vault{FungibleToken.Provider}>(
            /private/fusdProvider,
            target: /storage/fusdVault
        )
        
        self.collateralPool = FUSDPool(
            _receiver: self.account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver),
            _provider: self.account.getCapability<&FUSD.Vault{FungibleToken.Provider}>(/private/fusdProvider),
            _balance : self.account.getCapability<&FUSD.Vault{FungibleToken.Balance}>(/public/fusdBalance)
        )
        
        self.account.save(<- create Minter(), to: /storage/Minter)
        emit TokensInitialized(initialSupply:self.totalSupply)
    }
}