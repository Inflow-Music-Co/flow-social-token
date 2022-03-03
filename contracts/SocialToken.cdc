import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7
import FiatToken from 0xf8d6e0586b0a20c7

pub contract SocialToken: FungibleToken {

    // Total supply of all social tokens that are minted using this contract
    pub var totalSupply: UFix64

    // Events
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokensMinted(_ tokenId: String, _ mintPrice: UFix64, _ amount: UFix64)
    pub event TokensBurned(_ tokenId: String, _ burnPrice: UFix64, _ amount: UFix64)
    pub event SingleTokenMintPrice(_ tokenId: String, _ mintPrice: UFix64)
    pub event SingleTokenBurnPrice(_ tokenId: String, _ burnPrice: UFix64)

    // a variable that store admin capability to utilize methods of controller contract
    access(contract) let adminRef : Capability<&{Controller.SocialTokenResourcePublic}>
    // a variable which will store the structure of USDCPool
    pub var collateralPool: USDCPool

    pub resource interface SocialTokenPublic {
        pub fun getTokenId(): String 
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

        init(balance: UFix64) {
            self.balance = balance
            self.tokenId = ""
        }
        pub fun setTokenId(_ tokenId: String) {
            pre {
                tokenId !=nil: "token id must not be null"
            }
            self.tokenId = tokenId
        }
        pub fun getTokenId(): String {
            return self.tokenId
        }
        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from : @FungibleToken.Vault) {
            let vault <- from as! @SocialToken.Vault
            if(self.tokenId == "") {
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
            emit TokensWithdrawn(amount: amount, from: self.owner!.address)
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
    pub fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    // createNewMinter
    //
    // Function that creates a new minter
    // and returns it to the calling context. A user must call this function
    // and store the returned Minter in their storage in order to allow their
    // account to be able to mint new tokens.
    //
    pub fun createNewMinter(): @Minter {
        return <- create Minter()
    }
    
    // createNewBurner
    //
    // Function that creates a new burner
    // and returns it to the calling context. A user must call this function
    // and store the returned Burner in their storage in order to allow their
    // account to be able to burn tokens.
    //
    pub fun createNewBurner(): @Burner {
        return <- create Burner()
    }

    // A structure that contains all the data related to the USDCPool
    pub struct USDCPool {
        pub let receiver: Capability<&{FungibleToken.Receiver}>
        pub let provider: Capability<&{FungibleToken.Provider}>
        pub let balance : Capability<&{FungibleToken.Balance}>
        pub let resourceId : Capability<&FiatToken.Vault{FiatToken.ResourceId}>

        init(
            _receiver: Capability<&{FungibleToken.Receiver}>, 
            _provider: Capability<&{FungibleToken.Provider}>,
            _balance : Capability<&{FungibleToken.Balance}>,
            _resourceId : Capability<&FiatToken.Vault{FiatToken.ResourceId}>
           
            ) {
            self.receiver = _receiver
            self.provider = _provider
            self.balance = _balance
            self.resourceId = _resourceId
        }
    }
    // method to distribute fee of a token when a token minted, distribute to admin and artist
    access(contract) fun distributeFee(_ tokenId : String, _ usdcPayment: @FungibleToken.Vault): @FungibleToken.Vault {
        let amount = usdcPayment.balance
        let tokenDetails = Controller.getTokenDetails(tokenId)
        let detailData = tokenDetails.getFeeSplitterDetail()
        
        assert(detailData.length < 10, message: "Maximum Limit Reached. Please update Fee Structure")
        for address in detailData.keys {
            let feeStructuredetail = tokenDetails.getFeeSplitterDetail()
            let feeStructure = feeStructuredetail[address]
            let tempAmmount = amount * feeStructure!.percentage
            let tempraryVault <- usdcPayment.withdraw(amount:tempAmmount)
            let account = getAccount(address)
            let depositSigner= account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath)
            .borrow()
            ??panic("could not borrow reference to the receiver")
            depositSigner.deposit(from:<- tempraryVault)
        }
        return <- usdcPayment
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
        assert(amount + tokenDetails.issuedSupply <= tokenDetails.maxSupply , message: "maximum supply reached")
        if supply == 0.0 {
            return (tokenDetails.slope.saturatingMultiply((amount.saturatingMultiply(amount/2.0/10000.0))))
        } else {
            return ((reserve.saturatingMultiply(newSupply.saturatingMultiply(newSupply) / supply.saturatingMultiply(supply))) - reserve)
        }
    }  
    pub fun getBurnPrice(_ tokenId: String, _ amount: UFix64): UFix64 {
        pre { 
            amount > 0.0: "Amount must be greator than zero"
            Controller.getTokenDetails(tokenId).tokenId !=nil: "token not registered"
        }
        let decimalPoints: UFix64 = 1000.0
        let tokenDetails = Controller.getTokenDetails(tokenId)
        assert(tokenDetails.tokenId != "", message: "token id must not be null")
        let supply: Int256 = Int256(tokenDetails.issuedSupply)
        assert((tokenDetails.issuedSupply > 0.0), message: "Token supply is zero")
        assert((tokenDetails.issuedSupply >= amount), message: "amount greater than supply")
        let newSupply: Int256 = Int256((tokenDetails.issuedSupply - amount)).saturatingMultiply(Int256(decimalPoints))
        var _reserve = tokenDetails.reserve
        var supplyPercentage: UFix64 = UFix64(newSupply.saturatingMultiply(newSupply)/(supply.saturatingMultiply(supply)))/(decimalPoints*decimalPoints)
        return UFix64(_reserve - (_reserve.saturatingMultiply(supplyPercentage)))
    }
    
    pub resource interface MinterPublic {
        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, usdcPayment: @FungibleToken.Vault, receiverVault: Capability<&AnyResource{FungibleToken.Receiver}>): @SocialToken.Vault
    }

    pub resource Minter: MinterPublic {
        // mintTokens mints new tokens
        // 
        // Parameters:
        // tokenId: The ID of the token that will be minted
        // amount: amount to pay for the tokens
        // usdcPayment: will take the usdc balance
        // receiverVault: will return the remaining balance to the user
        // Pre-Conditions:
        // tokenId must not be null
        // amoutn must be greater than zero
        // issued supply will be less than or equal to maximum supply
        // 
        // Returns: The SocialToken Vault
        // 
        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, usdcPayment: @FungibleToken.Vault, receiverVault: Capability<&AnyResource{FungibleToken.Receiver}>): @SocialToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                usdcPayment.balance > 0.0: "Balance should be greater than zero"
                Controller.getTokenDetails(tokenId).tokenId !=nil: "toke not registered"
                amount + Controller.getTokenDetails(tokenId).issuedSupply <= Controller.getTokenDetails(tokenId).maxSupply : "Max supply reached"
                SocialToken.adminRef.borrow() !=nil: "social token does not have controller capability"
            }
            var remainingUSDC = 0.0
            var remainingSocialToken = 0.0
            let mintPrice = SocialToken.getMintPrice(tokenId, amount)
            let mintedTokenPrice = SocialToken.getMintPrice(tokenId, 1.0)
            assert(usdcPayment.balance >= mintPrice, message: "You don't have sufficient balance to mint tokens")
            var totalPayment = usdcPayment.balance
            assert(totalPayment>=mintPrice, message: "No payment yet")
            let extraAmount = totalPayment-mintPrice
            if(extraAmount > 0.0) {
                //Create Vault of extra amount and deposit back to user
                totalPayment=totalPayment-extraAmount
                let remainingAmountVault <- usdcPayment.withdraw(amount: extraAmount)
                let remainingVault = receiverVault.borrow()!
                remainingVault.deposit(from: <- remainingAmountVault)
            }
            let tempraryVar <- create SocialToken.Vault(balance: amount)
            tempraryVar.setTokenId(tokenId)
            let tokenDetails = Controller.getTokenDetails(tokenId)
            SocialToken.adminRef.borrow()!.incrementIssuedSupply(tokenId, amount)
            let remainingAmount <- SocialToken.distributeFee(tokenId, <- usdcPayment)
            SocialToken.totalSupply = SocialToken.totalSupply + amount
            
            SocialToken.adminRef.borrow()!.incrementReserve(tokenId, remainingAmount.balance)
            SocialToken.collateralPool.receiver.borrow()!.deposit(from:<- remainingAmount)
            emit TokensMinted(tokenId, mintPrice, amount)
            emit SingleTokenMintPrice(tokenId, mintedTokenPrice)
            return <- tempraryVar
        }
    }

    pub resource interface BurnerPublic {
        pub fun burnTokens(from: @FungibleToken.Vault) : @FungibleToken.Vault
    }

    pub resource Burner : BurnerPublic {
        // burnTokens burns tokens
        // 
        // Parameters:
        // It will take the Vault
        // and burn the tokens, decrement the issued supply and reserve of the tokens
        // 
        // Returns: The Vault
        // 
        pub fun burnTokens( from: @FungibleToken.Vault): @FungibleToken.Vault {
            let vault <- from as! @SocialToken.Vault
            let amount = vault.balance
            let tokenId = vault.getTokenId()
            let burnedTokenPrice = SocialToken.getBurnPrice(tokenId, 1.0)
            let burnPrice = SocialToken.getBurnPrice(tokenId, amount)
            let tokenDetails = Controller.getTokenDetails(tokenId)
            SocialToken.adminRef.borrow()!.decrementIssuedSupply(tokenId, amount)
            SocialToken.adminRef.borrow()!.decrementReserve(tokenId, burnPrice)
            emit TokensBurned(tokenId, burnPrice, amount)
            emit SingleTokenBurnPrice(tokenId, burnedTokenPrice)
            destroy vault
            return <- SocialToken.collateralPool.provider.borrow()!.withdraw(amount:burnPrice)
        }
    }

    init() {
        self.totalSupply = 0.0

        var adminPrivateCap = self.account.getCapability
            <&{Controller.SocialTokenResourcePublic}>(/private/SocialTokenResourcePrivatePath)
        
        self.adminRef = adminPrivateCap
        
        let vault <-FiatToken.createEmptyVault()
        // self.account.save(<-vault, to:FiatToken.VaultStoragePath)
        self.account.save(<-vault, to: FiatToken.VaultStoragePath)

          // Create a public capability to the Vault that only exposes
        // the deposit function through the Receiver interface
         self.account.link<&FiatToken.Vault{FungibleToken.Receiver}>(
            FiatToken.VaultReceiverPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the UUID() function through the VaultUUID interface
         self.account.link<&FiatToken.Vault{FiatToken.ResourceId}>(
            FiatToken.VaultUUIDPubPath,
            target: FiatToken.VaultStoragePath
        )

        // Create a public capability to the Vault that only exposes
        // the balance field through the Balance interface
         self.account.link<&FiatToken.Vault{FungibleToken.Balance}>(
            FiatToken.VaultBalancePubPath,
            target: FiatToken.VaultStoragePath
        )

         // Create a private capability to the Vault that only exposes
        // the balance field through the Balance interface
          self.account.link<&FiatToken.Vault{FungibleToken.Provider}>(
            /private/usdcProvider,
            target: FiatToken.VaultStoragePath
        )


        self.collateralPool = USDCPool(
            _receiver: self.account.getCapability<&FiatToken.Vault{FungibleToken.Receiver}>(FiatToken.VaultReceiverPubPath),
            _provider: self.account.getCapability<&FiatToken.Vault{FungibleToken.Provider}>(/private/usdcProvider),
            _balance : self.account.getCapability<&FiatToken.Vault{FungibleToken.Balance}>(FiatToken.VaultBalancePubPath),
            _resourceId : self.account.getCapability<&FiatToken.Vault{FiatToken.ResourceId}>(FiatToken.VaultUUIDPubPath)
        )
        emit TokensInitialized(initialSupply:self.totalSupply)
    }
}