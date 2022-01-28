import FungibleToken from 0x01cf0e2f2f715450
import Controller from 0xf3fcd2c1a78f5eee
import FUSD from 0x179b6b1cb6755e31

pub contract SocialToken : FungibleToken{

    pub var totalSupply:UFix64
    
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)

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
            log(self.tokenId)
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
                log(address)
                let feeStructer = Controller.allSocialTokens[tokenId]!.feeSplitterDetail[address]

                let tempAmmount = amount * feeStructer!.percentage
                let tempraryVault <- fusdPayment.withdraw(amount:tempAmmount)

                let account = getAccount(address)

                let depositSigner= account.getCapability<&FUSD.Vault{FungibleToken.Receiver}>(/public/fusdReceiver)
                .borrow()
                ??panic("could not borrow")
                
                depositSigner.deposit(from:<- tempraryVault)
                }
                return <- fusdPayment
            
        }
    pub resource Minter:MinterPublic {

        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment: @FungibleToken.Vault): @SocialToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                Controller.allSocialTokens[tokenId]!=nil: "toke not registered"
                amount + Controller.allSocialTokens[tokenId]!.issuedSupply <= Controller.allSocialTokens[tokenId]!.maxSupply: "Max supply reached"
            }
            let tempraryVar  <- create SocialToken.Vault(balance: amount)
            tempraryVar.setTokenId(tokenId)
            Controller.allSocialTokens[tokenId]!.incrementIssuedSupply(amount)
            let remainingAmount <-   SocialToken.distributeFee(tokenId,  <- fusdPayment)

            SocialToken.totalSupply = SocialToken.totalSupply + amount
            log(remainingAmount.balance)
            SocialToken.collateralPool.receiver.borrow()!.deposit(from:<- remainingAmount)
            return <- tempraryVar
        }


    }
    pub resource interface BurnerPublic{
        pub fun burnTokens(from: @FungibleToken.Vault) : @FungibleToken.Vault
    }
    pub resource Burner : BurnerPublic {
        pub fun burnTokens(from: @FungibleToken.Vault): @FungibleToken.Vault{
            let vault <- from as! @SocialToken.Vault
            let amountt = vault.balance
            destroy vault
        log(amountt)
            return <- SocialToken.collateralPool.provider.borrow()!.withdraw(amount:amountt)
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
 