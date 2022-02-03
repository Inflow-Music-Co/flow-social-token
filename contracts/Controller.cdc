import FungibleToken from 0xee82856bf20e2aa6
pub contract Controller {

    access(contract) var allSocialTokens :{String:TokenStructure}
    
    pub let AdminStoragePath: StoragePath
    pub var SocialTokenResourceStoragePath: StoragePath

    pub let SpecialCapabilityPrivatePath: PrivatePath
    pub let SocialTokenResourcePrivatePath: PrivatePath


    pub struct TokenStructure{
        pub var tokenId: String
        pub var symbol: String
        pub var issuedSupply: UFix64
        pub var maxSupply: UFix64
        pub var artist: Address
        pub var slope: UFix64
        pub var feeSplitterDetail : {Address:FeeStructure}
        pub var reserve: UFix64
        pub var tokenResourceStoragePath: StoragePath
        pub var tokenResourcePublicPath: PublicPath
        pub var socialMinterStoragePath: StoragePath
        pub var socialMinterPublicPath: PublicPath
        pub var socialBurnerStoragePath: StoragePath
        pub var socialBurnerPublicPath: PublicPath

        init(_ tokenId: String, _ symbol: String, _ maxSupply: UFix64, _ artist: Address,
            _ tokenStoragePath: StoragePath, _ tokenPublicPath: PublicPath,
            _ socialMinterStoragePath: StoragePath, _ socialMinterPublicPath: PublicPath,
            _ socialBurnerStoragePath: StoragePath, _ socialBurnerPublicPath: PublicPath){
            self.tokenId = tokenId
            self.symbol = symbol
            self.issuedSupply = 0.0
            self.maxSupply = maxSupply
            self.artist = artist
            self.slope = 0.5
            self.feeSplitterDetail = {}
            self.reserve = 0.0
            self.tokenResourceStoragePath = tokenStoragePath
            self.tokenResourcePublicPath = tokenPublicPath
            self.socialMinterStoragePath = socialMinterStoragePath
            self.socialMinterPublicPath = socialMinterPublicPath
            self.socialBurnerStoragePath = socialBurnerStoragePath
            self.socialBurnerPublicPath = socialBurnerPublicPath
        }

        pub fun incrementReserve(_ newReserve:UFix64){
            pre {
                newReserve != nil: "reserve must not be null"
                newReserve > 0.0 : "reserve must be greater than zero"
            }
            self.reserve = self.reserve + newReserve
        }

        pub fun decrementReserve(_ newReserve:UFix64){
            pre {
                newReserve != nil: "reserve must not be null"
                newReserve > 0.0 : "reserve must be greater than zero"
            }
            self.reserve = self.reserve - newReserve
        }


        pub fun incrementIssuedSupply(_ amount: UFix64){
            pre{
                self.issuedSupply + amount <= self.maxSupply : "max supply reached"
            }
            self.issuedSupply =  self.issuedSupply + amount

        }

        pub fun decrementIssuedSupply(_ amount: UFix64){
            pre {
                self.issuedSupply - amount >= 0.0 : "issued supply must not be zero"
            }
            self.issuedSupply = self.issuedSupply - amount
        
        }
        
        pub fun setFeeSpliterDetail(_ feeSplitterDetail:{Address: FeeStructure}){
            pre {
            }
            self.feeSplitterDetail = feeSplitterDetail
        }
    }

    pub resource interface SpecialCapability {
        pub fun registerToken( _ symbol: String, _ maxSupply: UFix64, _ feeSplitterDetail: {Address:FeeStructure}, _ artist: Address,
            _ tokenStoragePath: StoragePath, _ tokenPublicPath: PublicPath,
            _ socialMinterStoragePath: StoragePath, _ socialMinterPublicPath: PublicPath,
            _ socialBurnerStoragePath: StoragePath, _ socialBurnerPublicPath: PublicPath)
    }

    pub resource interface UserSpecialCapability {
        pub fun addCapability(cap: Capability<&{SpecialCapability}>)
    }

    pub resource interface SocialTokenResourcePublic {
        pub fun incrementIssuedSupply(_ tokenId: String, _ amount: UFix64)
        pub fun decrementIssuedSupply(_ tokenId: String, _ amount: UFix64)
        pub fun incrementReserve(_ tokenId: String, _ newResreve: UFix64)
        pub fun decrementReserve(_ tokenId: String, _ newReserve: UFix64)
    }

    pub resource Admin: SpecialCapability {  
        pub fun registerToken( _ symbol: String, _ maxSupply: UFix64, _ feeSplitterDetail: {Address:FeeStructure}, _ artist: Address,
            _ tokenStoragePath: StoragePath, _ tokenPublicPath: PublicPath,
            _ socialMinterStoragePath: StoragePath, _ socialMinterPublicPath: PublicPath,
            _ socialBurnerStoragePath: StoragePath, _ socialBurnerPublicPath: PublicPath){
            pre{
                symbol !=nil: "symbol must not be null"
                maxSupply > 0.0: "max supply must be greater than zero"
            }
            let artistAddress = artist
            let resourceOwner = self.owner!.address
            let tokenId = (symbol.concat("_")).concat(artistAddress.toString()) 
            assert(Controller.allSocialTokens[tokenId]==nil, message:"token already registered")     
            Controller.allSocialTokens[tokenId]= Controller.TokenStructure(
                tokenId, symbol, maxSupply, artistAddress,
                tokenStoragePath, tokenPublicPath,
                socialMinterStoragePath, socialMinterPublicPath,
                socialBurnerStoragePath, socialBurnerPublicPath)
            Controller.allSocialTokens[tokenId]!.setFeeSpliterDetail(feeSplitterDetail)
        } 
    }

    pub resource SocialTokenResource : SocialTokenResourcePublic , UserSpecialCapability {
        
        access(contract) var capability: Capability<&{SpecialCapability}>?
        pub fun addCapability (cap: Capability<&{SpecialCapability}>){
            pre {
                // we make sure the SpecialCapability is 
                // valid before executing the method
                cap.borrow() != nil: "could not borrow a reference to the SpecialCapability"
                self.capability == nil: "resource already has the SpecialCapability"
            }
            // add the SpecialCapability
            self.capability = cap
        }
        pub fun incrementIssuedSupply(_ tokenId: String, _ amount:UFix64){
            pre {
                amount > 0.0: "Amount must be greator than zero"
                tokenId != "" : "token id must not be null"
                Controller.allSocialTokens[tokenId]!=nil : "token id must not be null"
            }
            Controller.allSocialTokens[tokenId]!.incrementIssuedSupply(amount)
        }
        pub fun decrementIssuedSupply(_ tokenId: String, _ amount: UFix64){
            pre {
                amount > 0.0: "Amount must be greator than zero"
                tokenId != "" : "token id must not be null"
                Controller.allSocialTokens[tokenId]!=nil : "token id must not be null"
            }
            Controller.allSocialTokens[tokenId]!.decrementIssuedSupply(amount)        
        }
        pub fun incrementReserve(_ tokenId: String, _ newResreve: UFix64){
            pre {
                newResreve != nil: "reserve must not be null"
                newResreve > 0.0 : "reserve must be greater than zero"
                
            }
            Controller.allSocialTokens[tokenId]!.incrementReserve(newResreve)
        }
        pub fun decrementReserve(_ tokenId: String, _ newResreve: UFix64){
        
            pre {
                newResreve != nil: "reserve must not be null"
                newResreve > 0.0 : "reserve must be greater than zero"
                
            }
            Controller.allSocialTokens[tokenId]!.decrementReserve(newResreve)
        }
        
        init(){
            self.capability = nil
        
        }
    }

    pub struct FeeStructure{
        pub var percentage: UFix64

        init(_ percentage: UFix64){
            self.percentage = percentage
        }
        access(account) fun updatePercentage(_ percentage: UFix64){ 
            pre {
                percentage >0.0: "Percentage should be greater than zero"
            }
            self.percentage = percentage
        }
    }
    pub fun getTokenDetails(_ tokenId:String):Controller.TokenStructure{
        pre {
            tokenId!=nil:"token id must not be null of public functio"
            }
        return self.allSocialTokens[tokenId]!   
    }
    pub fun createSocialTokenResource(): @SocialTokenResource{
        return <- create SocialTokenResource()    
    }


    init(){
        self.allSocialTokens= {}
        self.AdminStoragePath = /storage/ControllerAdmin
        self.SocialTokenResourceStoragePath = /storage/ControllerSocialTokenResource  


        self.SpecialCapabilityPrivatePath = /private/ControllerSpecialCapability
        self.SocialTokenResourcePrivatePath = /private/ControllerSocialTokenResourcePrivate


        self.account.save<@Admin>(<- create Admin(), to: self.AdminStoragePath)
        self.account.link<&{SpecialCapability}>(  self.SpecialCapabilityPrivatePath, target: self.AdminStoragePath)
    }

}