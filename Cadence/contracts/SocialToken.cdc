import FungibleToken from 0xee82856bf20e2aa6
import Controller from 0xf8d6e0586b0a20c7
import FUSD from 0xf8d6e0586b0a20c7

pub contract SocialToken : FungibleToken{

    pub var totalSupply:UFix64
    
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokenIdSeted(_ tokenId: String)
    pub event FeeDistributed(_ tokenId: String, _ fusdPayment: @FungibleToken.Vault)
    pub event TokensMinted(_ tokenId: String, _ amount: UFix64, _ fusdPayment: @FungibleToken.Vault)
    pub event TokensBurned(_ amount: UFix64, _ from: @FungibleToken.Vault)

    pub var collateralPool: FUSDPool
    pub resource interface SocialTokenPublic{
        pub fun getTokenId():String 
    }

    pub resource Vault : SocialTokenPublic, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        pub var balance: UFix64
        pub var tokenId: String


        init(balance: UFix64){
            self.balance = balance
            self.tokenId = ""

        }
        pub fun setTokenId(_ tokenId: String){
            pre{
                tokenId !=nil: "token id must not be nil"
            }
            self.tokenId = tokenId
            emit TokenIdSeted(tokenId)
        }
        pub fun getTokenId(): String{
            return self.tokenId
        }
        pub fun deposit(from : @FungibleToken.Vault){
            let vault <- from as! @SocialToken.Vault
            self.balance = self.balance + vault.balance                        
            self.tokenId = vault.tokenId 
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)  
            vault.balance = 0.0      
            destroy vault
        }
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

    pub fun createEmptyVault(): @Vault{
        return <- create Vault(balance:0.0)
    }
    pub fun createNewMinter():@Minter{
        return <- create Minter()
    }
    pub fun createNewBurner():@Burner{
        return <- create Burner()
    }

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
    pub resource interface MinterPublic{
        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @FungibleToken.Vault): @SocialToken.Vault
    }
    access(contract) fun distributeFee(_ tokenId : String, _ fusdPayment: @FungibleToken.Vault): @FungibleToken.Vault{
            let amount = fusdPayment.balance
            for  address in   Controller.allSocialTokens[tokenId]!.feeSplitterDetail.keys {
                let feeStructer = Controller.allSocialTokens[tokenId]!.feeSplitterDetail[address]

                let tempAmmount = amount * feeStructer!.percentage
                let tempraryVault <- fusdPayment.withdraw(amount:tempAmmount)

                let account = getAccount(address)

                let depositSigner= account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
                .borrow()
                ??panic("could not borrow")
                emit FeeDistributed(tokenId, fusdPayment)
                depositSigner.deposit(from:<- tempraryVault)
                }
                return <- fusdPayment
            
        }
        pub fun getMintPrice(_ tokenId: String, _ amount: UFix64): UFix64 {
            pre { 
                amount > 0.0: "Amount must be greator than zero"
                tokenId != "" : "token id must not be null"
                Controller.allSocialTokens[tokenId] !=nil: "token not registered"
            }
            let supply =  Controller.allSocialTokens[tokenId]!.issuedSupply
            let newSupply = supply + amount
            let reserve = Controller.allSocialTokens[tokenId]!.reserve
            if supply == 0.0 {
                let a :UFix64 = 10000.0
                return ( (Controller.allSocialTokens[tokenId]!.slope * amount * amount)/2.0/a ) 
            } else {
                return (((reserve * newSupply * newSupply) / (supply * supply)) - reserve)
            }
        }  
        pub fun getBurnPrice(_ tokenId: String, _ amount: UFix64): UFix64{
            pre { 
                amount > 0.0: "Amount must be greator than zero"
                tokenId != "" : "token id must not be null"
                Controller.allSocialTokens[tokenId] !=nil: "token not registered"
            }
            let supply = Controller.allSocialTokens[tokenId]!.issuedSupply
            assert((supply > 0.0), message: "Token supply is zero")    
            assert((supply>=amount), message: "amount greater than supply")
            let newSupply = supply - amount
            var _reserve = Controller.allSocialTokens[tokenId]!.reserve;
            return (_reserve - ((_reserve * newSupply * newSupply) / (supply * supply)))
        }

    pub resource Minter:MinterPublic {

        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @FungibleToken.Vault): @SocialToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                Controller.allSocialTokens[tokenId]!=nil: "toke not registered"
                amount + Controller.allSocialTokens[tokenId]!.issuedSupply <= Controller.allSocialTokens[tokenId]!.maxSupply: "Max supply reached"
            }
            let mintPrice = SocialToken.getMintPrice(tokenId, amount)

            assert(fusdPayment.balance >=mintPrice,message: "don't have suffiecent balance to mint tokens")
            let tempraryVar  <- create SocialToken.Vault(balance: amount)
            tempraryVar.setTokenId(tokenId)
            Controller.allSocialTokens[tokenId]!.incrementIssuedSupply(amount)
            let remainingAmount <-   SocialToken.distributeFee(tokenId,  <- fusdPayment)
            SocialToken.totalSupply = SocialToken.totalSupply + amount
            Controller.allSocialTokens[tokenId]!.reserve == remainingAmount.balance  
            SocialToken.collateralPool.receiver.borrow()!.deposit(from:<- remainingAmount)
            emit  TokensMinted(tokenId, amount, fusdPayment)
            return <- tempraryVar
        }

    }
    pub resource interface BurnerPublic{
        pub fun burnTokens(from: @FungibleToken.Vault) : @FungibleToken.Vault
    }
    pub resource Burner : BurnerPublic {
        pub fun burnTokens(from: @FungibleToken.Vault): @FungibleToken.Vault{
            let vault <- from as! @SocialToken.Vault
            let amount = vault.balance
            let tokenId = vault.tokenId
            let burnPrice = SocialToken.getBurnPrice(tokenId, amount)
            Controller.allSocialTokens[tokenId]!.reserve ==  Controller.allSocialTokens[tokenId]!.reserve - burnPrice
            SocialToken.totalSupply = SocialToken.totalSupply - amount
            emit TokensBurned(amount, from)
            destroy vault
            return <- SocialToken.collateralPool.provider.borrow()!.withdraw(amount:burnPrice)
        }
    }

    init(){
        self.totalSupply = 0.0
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