import FungibleToken from "./FungibleToken.cdc"
import Controller from "./Controller.cdc"

pub contract SocialToken : FungibleToken{

    pub var totalSupply:UFix64
    
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)

    
    pub resource interface SocialTokenPublic{
        pub fun getTokenId():String
    
    }

    pub resource Vault : SocialTokenPublic, FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        pub var balance : UFix64
        pub var tokenId: String


        init(balance:UFix64){
            self.balance = balance
            self.tokenId = ""

        }
        pub fun setTokenId(_ tokenId:String){
            pre{
                tokenId !=nil: "token id must not be nil"
            }
            self.tokenId = tokenId
        }
        /*
      
        */
        pub fun getTokenId():String{
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
    pub resource interface MinterPublic{
        pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment:@FungibleToken.Vault): @SocialToken.Vault
    }
    pub resource Minter:MinterPublic {

       pub fun mintTokens(_ tokenId: String, _ amount: UFix64, fusdPayment:@FungibleToken.Vault): @SocialToken.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                Controller.allSocialTokens[tokenId]!=nil: "toke not registered"
                amount + Controller.allSocialTokens[tokenId]!.issuedSupply <= Controller.allSocialTokens[tokenId]!.maxSupply: "Max supply reached"
            }
            let tempraryVar  <- create SocialToken.Vault(balance: amount)
            tempraryVar.setTokenId(tokenId)
            Controller.allSocialTokens[tokenId]!.incrementIssuedSupply(amount)
            SocialToken.totalSupply = SocialToken.totalSupply + amount
            destroy   fusdPayment
            return <- tempraryVar
        }

    }
    pub resource interface BurnerPublic{
     pub fun burnTokens(from: @FungibleToken.Vault) 
    }
    pub resource Burner : BurnerPublic {
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault <- from as! @SocialToken.Vault
            let amount = vault.balance
            destroy vault
        }
    }

    init(){
        self.totalSupply = 0.0

        self.account.save(<- create Minter(), to: /storage/Minter)
        emit TokensInitialized(initialSupply:self.totalSupply)
    }

}