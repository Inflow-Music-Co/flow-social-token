import FungibleToken from 0x01cf0e2f2f715450
pub contract Controller {

    pub var allSocialTokens : {String:TokenStructure}
    pub var allArtist : {Address:Artist}

    pub event TokenRegistered(_ symbol:String, _ maxSupply: UFix64, _ artist: Address)

    pub var AdminResourceStoragePath: StoragePath

    pub struct TokenStructure{
        pub var tokenId: String
        pub var symbol: String
        pub var issuedSupply: UFix64
        pub var maxSupply: UFix64
        pub var artist: Address
        pub var slope: UFix64
        pub var feeSplitterDetail : {Address:FeeStructure}
        pub var mintQoute: UFix64
        pub var reserve: UFix64

    

        init(_ tokenId: String, _ symbol: String, _ maxSupply: UFix64, _ artist: Address){
            self.tokenId = tokenId
            self.symbol = symbol
            self.issuedSupply = 0.0
            self.maxSupply = maxSupply
            self.artist = artist
            self.slope = 0.0005
            self.feeSplitterDetail = {}
            self.mintQoute = 0.0
            self.reserve = 0.0
        }

        pub fun incrementIssuedSupply(_ amount: UFix64){
            pre{
                self.issuedSupply + amount <= self.maxSupply : "max supply reached"
            }
            self.issuedSupply = self.issuedSupply + amount
        }
        pub fun setFeeSpliterDetail(_ feeSplitterDetail:{Address: FeeStructure}){
            pre {
            }
            self.feeSplitterDetail = feeSplitterDetail
        }
    }
    pub struct Artist {
        pub let address: Address
        pub let tokenIds: [String]

        init(_ address:Address){

            self.address = address
            self.tokenIds = []
        }
        pub fun addToken(_ tokenId: String){
            pre {
                self.tokenIds.contains(tokenId)==false:"Token already added"
            }
            self.tokenIds.append(tokenId)
        }
        

    }
    pub struct FeeStructure{
        pub var percentage: UFix64

        init(_ percentage: UFix64){
            self.percentage = percentage
        }

        pub fun updatePercentage(_ percentage: UFix64){ 
            pre {
                percentage >0.0: "Percentage should be greater than zero"
            }
            self.percentage = percentage
        }
    }



    pub resource Admin {

        pub fun registerToken( _ symbol: String, _ maxSupply: UFix64, _ feeSplitterDetail: {Address:FeeStructure}, _ artist: Address){
            pre{
                symbol !=nil: "symbol must not be null"
                maxSupply > 0.0: "max supply must be greater than zero"
            }
            let artistAddress = artist

            //let tokenId = (artistAddress.toString().concat("_")).concat(symbol)
            let tokenId = (symbol.concat("_")).concat(artistAddress.toString())            
            assert(Controller.allSocialTokens[tokenId]==nil, message: "token already registered")
            Controller.allSocialTokens[tokenId] = Controller.TokenStructure(tokenId, symbol,maxSupply,artistAddress )
            emit TokenRegistered(tokenId,maxSupply,artistAddress)
            Controller.allSocialTokens[tokenId]!.setFeeSpliterDetail(feeSplitterDetail)
        }
        init(){
        }

    }
    pub fun getMintPrice(_ tokenId: String, _ amount: UFix64): UFix64{
        pre { 
            amount > 0.0: "Amount must be greator than zero"
            tokenId != "" : "token id must not be null"
            Controller.allSocialTokens[tokenId] !=nil: "token not registered"
        }

        let supply =  Controller.allSocialTokens[tokenId]!.issuedSupply
        if supply == 0.0 {
            return ( Controller.allSocialTokens[tokenId]!.slope * amount) 
        } else {
        // new supply value after adding amount
            let newSupply = supply + amount

            var _reserve = Controller.allSocialTokens[tokenId]!.reserve
     
            return (((_reserve * newSupply * newSupply) / (supply * supply)) - _reserve)
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
    



    init(){
        self.allSocialTokens = {}
        self.allArtist = {}
        self.AdminResourceStoragePath = /storage/ControllerAdmin
        self.account.save<@Admin>(<- create Admin(), to : self.AdminResourceStoragePath)
    }
}