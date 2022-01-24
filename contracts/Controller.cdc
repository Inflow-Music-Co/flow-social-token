import FungibleToken from "./FungibleToken.cdc"

pub contract Controller {

    pub var allSocialTokens : {String:TokenStructure}
    pub var allArtist :{Address:Artist}

    pub var AdminResourceStoragePath: StoragePath
    
    pub var ArtistInterfacePrivatePath: PrivatePath


    pub struct TokenStructure{
        pub var tokenId: String
        pub var symbol : String
        pub var issuedSupply:UFix64
        pub var maxSupply: UFix64
        pub var artist: Address
        pub var slope : UFix64
        pub var feeSplitterDetail : {Address:FeeStructure}
        pub var mintQoute : UFix64
        pub var reserve : UFix64

    

        init(_ tokenId: String, _ symbol:String, _ maxSupply:UFix64, _ artist:Address){
            self.tokenId = tokenId
            self.symbol = symbol
            self.issuedSupply = 0.0
            self.maxSupply = maxSupply
            self.artist = artist
            self.slope = 0.0
            self.feeSplitterDetail ={}
            self.mintQoute = 0.0
            self.reserve = 0.0
        }

        pub fun incrementIssuedSupply(_ amount:UFix64){
            pre{
                self.issuedSupply + amount <= self.maxSupply : "max supply reached"
            }
            self.issuedSupply = self.issuedSupply + amount
        }
     
    }
   
    pub struct Artist {
        pub let address: Address
        pub let tokenIds:[String]

        init(_ address:Address){

            self.address = address
            self.tokenIds = []
        
        
        }
        pub fun addToken(_ tokenId:String){
            pre {
                self.tokenIds.contains(tokenId)==false:"Token already added"
            }
            self.tokenIds.append(tokenId)
        }
        

    }
    pub struct FeeStructure{
        pub var percentage:UFix64

        init(_ percentage:UFix64){
            self.percentage = percentage
        }

        pub fun updatePercentage(_ percentage:UFix64){ 
            pre {
                percentage >0.0: "Percentage should be greater than zero"
            }
            self.percentage = percentage
        }
    }

    pub resource interface ArtistCapability {
        pub  fun addCapability(cap: Capability<&{ArtistInterface}>)
    }

    pub resource interface ArtistInterface{
        pub fun registerToken(_ symbol:String, _ maxSupply:UFix64, _ feeSplitterDetail:{Address:FeeStructure})
    }


    pub resource ArtistResource :ArtistCapability, ArtistInterface {

        access(contract) var capability: Capability<&{ArtistInterface}>?

        pub fun addCapability(cap: Capability<&{ArtistInterface}>) {
            pre {
                // we make sure the SpecialCapability is 
                // valid before executing the method
                cap.borrow() != nil: "could not borrow a reference to the SpecialCapability"
                self.capability == nil: "resource already has the SpecialCapability"
            }
            // add the SpecialCapability
 
            self.capability = cap

        }

        pub fun registerToken( _ symbol:String, _ maxSupply:UFix64, _ feeSplitterDetail:{Address:FeeStructure}){
            pre{
            
                self.capability != nil: "I don't have the special capability :("
                symbol !=nil: "symbol must not be null"
                maxSupply >0.0:"max supply must be greater than zero"
            }
            let artistAddress = self.owner!.address
            //let tokenId = (artistAddress.toString().concat("_")).concat(symbol)
            let tokenId = (symbol.concat("_")).concat(artistAddress.toString())            
            assert(Controller.allSocialTokens[tokenId]==nil, message: "token already registered")
            Controller.allSocialTokens[tokenId] = Controller.TokenStructure(tokenId, symbol,maxSupply,artistAddress )
        }
        init(){
            self.capability = nil
        }

    }
    
    pub fun createAdminResource(): @ArtistResource{
        return <- create ArtistResource()    
    }


    pub fun distributeFee(_ fusdPayment:@FungibleToken.Vault, _ amount:UFix64, _ tokenId:String):@FungibleToken.Vault{
    
        return <- fusdPayment
    
    }
    pub fun getMintPrice(_ amount:UFix64, _ tokenId:String):UFix64{
        return amount
    }
    pub fun getBurnPrice(_ amount:UFix64, _ tokenId:String):UFix64{
        return amount
    }


    init(){
        self.allSocialTokens = {}
        self.allArtist = {}
        self.AdminResourceStoragePath = /storage/ControllerAdmin
        self.ArtistInterfacePrivatePath = /private/ControllerArtist

        self.account.save<@ArtistResource>(<- create ArtistResource(), to : self.AdminResourceStoragePath)
        self.account.link<&{ArtistInterface}>(self.ArtistInterfacePrivatePath, target: self.AdminResourceStoragePath)

    }

}